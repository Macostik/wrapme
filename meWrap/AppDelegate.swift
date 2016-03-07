//
//  AppDelegate.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import WatchConnectivity

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow? = UIWindow.mainWindow
    
    var versionChanged = false
    
    let wormhole = MMWormhole(applicationGroupIdentifier: "group.com.ravenpod.wraplive", optionalDirectory: "wormhole")
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        Logger.log("API environment: \(Environment.currentEnvironment)")
        
        registerUserNotificationSettings()
        initializeCrashlyticsAndLogging()
        NotificationCenter.defaultCenter.configure()
        createWindow()
        presentInitialViewController()
        initializeVersionTool()
        
        Network.sharedNetwork.addReceiver(self)
        
        if let notification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [String:AnyObject] {
            NotificationCenter.defaultCenter.handleRemoteNotification(notification, success: { $0.presentWithIdentifier(nil) }, failure: { $0?.show() })
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
            if Environment.currentEnvironment.isProduction {
                NewRelicAgent.startWithApplicationToken("AAd46869ec0b3558fb5890343d895b3acdd40ebaa8")
                GAI.sharedInstance().trackerWithTrackingId("UA-60538241-1")
            } else {
                NewRelicAgent.startWithApplicationToken("AA0d33ab51ad09e9b52f556149e4a7292c6d4c480c")
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
        let version = iVersion.sharedInstance()
        version.appStoreID = UInt(Constants.appStoreID)
        version.updateAvailableTitle = "new_version_is_available".ls
        version.downloadButtonLabel = "update".ls
        version.remindButtonLabel = "not_now".ls
        version.updatePriority = .Medium
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
            if user.isSignupCompleted {
                UIStoryboard.main.present(true)
            } else {
                Logger.log("INITIAL SIGN IN - sign up is not completed, redirecting to profile step")
                let navigation = UIStoryboard.signUp.instantiateInitialViewController() as? UINavigationController
                let signupFlowViewController = Storyboard.SignupFlow.instantiate()
                signupFlowViewController.registrationNotCompleted = true
                navigation?.viewControllers = [signupFlowViewController]
                UIWindow.mainWindow.rootViewController = navigation
            }
        };
        
        let authorization = Authorization.current
        if authorization.canAuthorize {
            if !versionChanged && !Authorization.requiresSignIn() {
                if let currentUser = User.currentUser {
                    successBlock(currentUser);
                    currentUser.notifyOnAddition()
                    return;
                }
            }
            UIWindow.mainWindow.rootViewController = UIStoryboard.introduction["launchScreen"]
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
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        let state = UIApplication.sharedApplication().applicationState
        if state == .Active {
            completionHandler(.NoData)
            return
        }
        let presentable = state == .Inactive
        NotificationCenter.defaultCenter.handleRemoteNotification(userInfo as? [String:AnyObject], success: { notification in
            if (presentable) {
                notification.presentWithIdentifier(nil)
            }
            completionHandler(.NewData)
            }, failure: { error in
                completionHandler(.Failed)
        })
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        NotificationCenter.defaultCenter.handleRemoteNotification(userInfo as? [String:AnyObject], success: { notification in
            notification.presentWithIdentifier(nil)
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
    
    private var retryResetBadge = false
    
    private func resetBadge() {
        if UIApplication.sharedApplication().applicationIconBadgeNumber > 0 {
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            APIRequest.resetBadge().send({ _ in }) { (error) -> Void in
                if error?.isNetworkError == true {
                    self.retryResetBadge = true
                }
            }
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        if Authorization.active {
            resetBadge()
            Dispatch.mainQueue.async { Uploader.wrapUploader.start() }
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

extension AppDelegate: NetworkNotifying {
    
    func networkDidChangeReachability(network: Network) {
        if network.reachable {
            if retryResetBadge {
                retryResetBadge = false
                resetBadge()
            }
            if Authorization.active {
                Uploader.wrapUploader.start()
            } else if Authorization.current.canAuthorize {
                Authorization.current.signIn().send()
            }
        }
    }
}