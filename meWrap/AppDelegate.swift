//
//  AppDelegate.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import WatchConnectivity
import Siren

extension UIApplication {
    
    static var isActive: Bool {
        return sharedApplication().applicationState == .Active
    }
}

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow? = UIWindow.mainWindow
    
    var versionChanged = false
    
    let wormhole = MMWormhole(applicationGroupIdentifier: "group.com.ravenpod.wraplive", optionalDirectory: "wormhole")
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        Logger.configure()
        Logger.log("API environment: \(Environment.current)")
        
        registerUserNotificationSettings()
        initializeCrashlyticsAndLogging()
        
        createWindow()
        presentInitialViewController()
        initializeVersionTool()
        
        Network.network.subscribe(self) { [unowned self] reachable in
            if reachable {
                if self.retryResetBadge {
                    self.retryResetBadge = false
                    self.resetBadge()
                }
                if Authorization.active {
                    Uploader.wrapUploader.start()
                } else if Authorization.current.canAuthorize {
                    Authorization.current.signIn().send()
                }
            }
        }
        
        if let notification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [String:AnyObject] {
            NotificationCenter.handleRemoteNotification(notification, success: { $0.presentWithIdentifier(nil) }, failure: { $0?.show() })
        }
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        if #available(iOS 9.0, *) {
            if WCSession.isSupported() {
                let session = WCSession.defaultSession()
                session.delegate = self
                session.activateSession()
            }
        }
        
        wormhole.listenForMessageWithIdentifier("recentUpdatesRequest", listener: { [weak self] _ in
            self?.wormhole.passMessageObject(Contribution.recentUpdates(6), identifier:"recentUpdatesResponse")
        })
        
        return true
    }
    
    private func initializeCrashlyticsAndLogging() {
        #if !DEBUG
            NewRelicAgent.enableCrashReporting(true)
            NewRelicAgent.startWithApplicationToken(Environment.current.newRelicToken)
            if let trackerId = Environment.current.GAITrackingId {
                GAI.sharedInstance().trackerWithTrackingId(trackerId)
            }
        #endif
    }
    
    private func registerUserNotificationSettings() {
        let category = UIMutableUserNotificationCategory()
        category.identifier = "chat"
        let action = UIMutableUserNotificationAction()
        action.identifier = "reply"
        action.title = "reply".ls
        action.activationMode = .Foreground
        action.authenticationRequired = true
        category.setActions([action], forContext:.Default)
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories:[category])
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    private func initializeVersionTool() {
        let siren = Siren.sharedInstance
        siren.alertType = .Force
        siren.checkVersion(.Immediately)
    }
    
    private func createWindow() {
        UIWindow.mainWindow.makeKeyAndVisible()
        
        let storedVersion = NSUserDefaults.standardUserDefaults().appVersion
        let currentVersion = NSBundle.mainBundle().buildVersion
        
        if storedVersion == nil || storedVersion?.compare("2.0", options:.NumericSearch) == .OrderedAscending {
            NSUserDefaults.standardUserDefaults().clear()
        }
        
        if storedVersion != currentVersion {
            versionChanged = true
            NSUserDefaults.standardUserDefaults().appVersion = currentVersion
        }
    }
    
    func presentInitialViewController() {
        let successBlock: User -> Void = { user in
            if user.name != nil {
                UIStoryboard.main.present(true)
            } else {
                Logger.log("INITIAL SIGN IN - sign up is not completed, redirecting to profile step")
                let signupFlowViewController = Storyboard.SignupFlow.instantiate()
                signupFlowViewController.registrationNotCompleted = true
                UINavigationController.main.viewControllers = [signupFlowViewController]
            }
        };
        
        let authorization = Authorization.current
        if authorization.canAuthorize {
            if !versionChanged && !Authorization.requiresSignIn() {
                if let currentUser = User.currentUser {
                    successBlock(currentUser)
                    return;
                }
            }
            UINavigationController.main.viewControllers = [UIStoryboard.introduction["launchScreen"]!]
            authorization.signIn().send({ _ in
                successBlock(User.currentUser!)
                }, failure: { error in
                    
                    if let currentUser = User.currentUser where error?.isNetworkError == true {
                        successBlock(currentUser)
                    } else {
                        UIAlertController.confirmReauthorization({ _ in
                            Logger.log("INITIAL SIGN IN ERROR - couldn't sign in, so redirecting to welcome screen")
                            UIStoryboard.signUp.present(true)
                            }, tryAgain: { [weak self] _ in
                                self?.presentInitialViewController()
                            })
                    }
            })
        } else {
            Logger.log("INITIAL SIGN IN - no data for signing in")
            UIStoryboard.signUp.present(true)
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        NotificationCenter.defaultCenter.handleDeviceToken(deviceToken)
    }
    
    private var forceResetBadge = false
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        if (userInfo["aps"] as? [String:AnyObject])?["alert"] != nil {
            forceResetBadge = true
        }
        
        let state = UIApplication.sharedApplication().applicationState
        if state == .Active {
            completionHandler(.NoData)
            return
        }
        let presentable = state == .Inactive
        NotificationCenter.handleRemoteNotification(userInfo as? [String:AnyObject], success: { notification in
            if (presentable) {
                notification.presentWithIdentifier(nil)
            } else {
                _ = try? EntryContext.sharedContext.save()
            }
            completionHandler(.NewData)
            }, failure: { error in
                completionHandler(.Failed)
        })
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        NotificationCenter.handleRemoteNotification(userInfo as? [String:AnyObject], success: { notification in
            notification.presentWithIdentifier(identifier)
            completionHandler()
            }, failure: { error in
                completionHandler()
        })
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        guard url.host == "extension.com" else { return false }
        guard let components = url.pathComponents else { return false }
        guard components.count >= 2 else { return false }
        guard components[components.count - 2] == "request" else { return false }
        guard let lastComponenet = components.last else { return false }
        let request = ExtensionRequest.deserialize(lastComponenet)
        request?.perform({ _ in }, failure: { $0.generateError().show() })
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if Authorization.active {
            Uploader.wrapUploader.start()
            Dispatch.mainQueue.after(20) { completionHandler(.NewData) }
        } else {
            completionHandler(.Failed)
        }
    }
    
    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        return [.All]
    }
    
    private var retryResetBadge = false
    
    private func resetBadge() {
        if UIApplication.sharedApplication().applicationIconBadgeNumber > 0 || forceResetBadge {
            forceResetBadge = false
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            let task = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
            API.resetBadge().send({ _ in
                UIApplication.sharedApplication().endBackgroundTask(task)
            }) { (error) -> Void in
                UIApplication.sharedApplication().endBackgroundTask(task)
                if error?.isNetworkError == true {
                    self.retryResetBadge = true
                }
            }
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        if Authorization.active {
            Dispatch.mainQueue.async { Uploader.wrapUploader.start() }
        }
        NotificationCenter.defaultCenter.applicationDidBecomeActive()
        Siren.sharedInstance.checkVersion(.Daily)
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        Siren.sharedInstance.checkVersion(.Immediately)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        FlowerMenu.sharedMenu.hide()
        if Authorization.active {
            NotificationCenter.defaultCenter.applicationWillResignActive()
            resetBadge()
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if notification.sin_isSinchNotification() {
            // This will trigger -[SINClientDelegate didReceiveIncomingCall:] if the notification
            // represents a call (i.e. contrast to that it may represent an instant-message)
            if let result = CallCenter.center.sinch?.relayLocalNotification(notification) {
                if result.isCall() && result.callResult().isTimedOut {
                    // The notification is related to an incoming call,
                    // but was too old and the call has expired.
                    // The call should be treated as a missed call and appropriate
                    // action should be taken to communicate that to the user.
                }
            }
        }
    }
}

extension AppDelegate: WCSessionDelegate {
    @available(iOS 9.0, *)
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        let task = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            replyHandler(["error":ExtensionError(message:"Background task expired.").toDictionary()])
        }
        
        if let requestData = message["request"] as? [String : AnyObject] {
            let request = ExtensionRequest.fromDictionary(requestData)
            request.perform({ (reply) -> Void in
                replyHandler(["success":reply.toDictionary()])
                UIApplication.sharedApplication().endBackgroundTask(task)
                }, failure: { (error) -> Void in
                    replyHandler(["error":error.toDictionary()])
                    UIApplication.sharedApplication().endBackgroundTask(task)
            })
        }
    }
}
