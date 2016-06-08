//
//  NotificationCenter+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import PubNub

extension NSData {
    func serializeDevicePushToken() -> String {
        var bytes = [UInt8](count: length, repeatedValue: 0)
        getBytes(&bytes, length: length)
        return bytes.reduce("", combine: { $0 + String(format:"%02x", UInt($1)) })
    }
}

final class NotificationCenter: NSObject, EntryNotifying, PNObjectEventListener {
    
    static let defaultCenter = specify(NotificationCenter()) { center in
        Network.network.subscribe(center, block: { [unowned center] reachable in
            if reachable {
                center.requestHistory()
                center.refreshUserActivities(true, completionHandler: nil)
            }
        })
        User.notifier().addReceiver(center)
        center.runQueue.didFinish = {
            if !center.notificationsToSubmit.isEmpty {
                NotificationCenter.addHandledNotifications(center.notificationsToSubmit)
                for notification in center.notificationsToSubmit {
                    notification.submit()
                }
                center.notificationsToSubmit.removeAll()
            }
            center.queryingHistory = false
        }
    }
    
    private let runQueue = RunQueue(limit: 1)
    
    var groupName = ""
    weak var liveSubscription: NotificationSubscription?
    private var notificationsToSubmit = [Notification]()
    
    var pushToken: String?
    var pushTokenData: NSData?
    
    func applicationDidBecomeActive() {
        liveSubscription?.subscribe()
        subscribe()
    }
    
    func applicationWillResignActive() {
        let task = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
        Dispatch.mainQueue.after(15) {
            if UIApplication.sharedApplication().applicationState != .Active {
                PubNub.sharedInstance.unsubscribeFromChannelGroups([self.groupName], withPresence: true)
            }
            Dispatch.mainQueue.after(1) {
                UIApplication.sharedApplication().endBackgroundTask(task)
            }
        }
    }
    
    func handleDeviceToken(deviceToken: NSData) {
        pushTokenData = deviceToken
        pushToken = deviceToken.serializeDevicePushToken()
        if Authorization.active {
            API.updateDevice().send()
        }
    }
    
    func subscribe(user: User? = User.currentUser) {
        guard let user = user where !user.uid.isEmpty else { return }
        let groupName = "cg-\(user.uid)"
        if self.groupName != groupName {
            if !self.groupName.isEmpty {
                PubNub.sharedInstance.unsubscribeFromChannelGroups([self.groupName], withPresence: true)
            }
            self.groupName = groupName
            if pushToken != nil {
                if Authorization.active {
                    API.updateDevice().send()
                }
            } else {
                #if !DEBUG
                    UIApplication.sharedApplication().registerForRemoteNotifications()
                #endif
            }
        }
        let channel = User.uuid()
        PubNub.sharedInstance.subscribeToChannels([channel], withPresence: false)
        PubNub.sharedInstance.subscribeToChannelGroups([groupName], withPresence: true)
        Logger.logglyDestination.userid = channel
        requestHistory()
        refreshUserActivities(true, completionHandler: nil)
    }
    
    func clear() {
        PubNub.sharedInstance.unsubscribeFromAll()
        NSUserDefaults.standardUserDefaults().clearHandledNotifications()
        NSUserDefaults.standardUserDefaults().historyDate = nil
        NSUserDefaults.standardUserDefaults().historyDates = [String:NSNumber]()
    }
    
    class func addHandledNotifications(notifications: [Notification]) {
        
        var handledNotifications = NSUserDefaults.standardUserDefaults().handledNotifications
        if handledNotifications.count > 100 {
            handledNotifications.removeFirst(min(100, notifications.count))
        }
        for notification in notifications {
            if let uid = notification.uid {
                handledNotifications.append(uid)
            }
        }
        
        NSUserDefaults.standardUserDefaults().handledNotifications = handledNotifications
    }
    
    class func canSkipNotification(notification: Notification) -> Bool {
        if let uid = notification.uid {
            return NSUserDefaults.standardUserDefaults().handledNotifications.contains(uid) ?? false
        } else {
            return true
        }
    }
    
    func notificationsFromMessages(messages: [AnyObject], isHistorycal: Bool = true) -> [Notification] {
        
        guard !messages.isEmpty else { return [] }
        
        var notifications = [Notification]()
        
        for message in messages {
            if let n = notificationFromMessage(message, isHistorycal: isHistorycal) {
                notifications.append(n)
            }
        }
        
        if notifications.isEmpty { return notifications }
        
        NotificationCenter.addHandledNotifications(notifications)
        
        return notifications
    }
    
    private func notificationFromMessage(message: AnyObject, isHistorycal: Bool = true) -> Notification? {
        guard let n = Notification.notificationWithMessage(message) else { return nil }
        guard n.canBeHandled() && !NotificationCenter.canSkipNotification(n) else { return nil }
        n.isHistorycal = isHistorycal
        return n
    }
    
    let historyNotifier = BlockNotifier<NotificationCenter>()
    
    var queryingHistory = false {
        didSet {
            if queryingHistory != oldValue {
                historyNotifier.notify(self)
            }
        }
    }
    
    func requestHistory() {
        runQueue.run { [unowned self] finish in
            
            guard !self.groupName.isEmpty && Network.network.reachable && UIApplication.isActive else {
                finish()
                return
            }
            
            self.queryingHistory = true
            
            PubNub.sharedInstance.allHistoryForChannelGroup(self.groupName, completionHandler: { (messages) in
                if case let notifications = self.notificationsFromMessages(messages) where !notifications.isEmpty {
                    self.handleNotifications(notifications)
                } else {
                    self.queryingHistory = false
                }
                finish()
            })
        }
    }
    
    private func handleNotifications(notifications: [Notification]) {
        for notification in notifications {
            handleNotification(notification)
        }
    }
    
    private func handleNotification(notification: Notification) {
        Logger.log("PubNub message received \(notification)")
        notificationsToSubmit.append(notification)
        runQueue.run { finish in
            Logger.log("Fetching notification \(notification)")
            notification.fetch({ _ in
                Logger.log("Fetching notification success \(notification)")
                finish()
                }, failure: { error in
                    Logger.log("Fetching notification error \(notification): \(error ?? "")")
                    finish()
            })
        }
    }
    
    class func handleRemoteNotification(data: [String:AnyObject]?, success: Notification -> Void, failure: FailureBlock?) {
        guard let data = data else  {
            failure?(nil)
            return
        }
        
        if let notification = Notification.notificationWithBody(data) {
            Logger.log("APNS received: \(notification.description)")
            if canSkipNotification(notification) {
                success(notification)
            } else {
                _ = try? EntryContext.sharedContext.save()
                notification.handle({ () -> Void in
                    addHandledNotifications([notification])
                    success(notification)
                    }, failure: { failure?($0) })
            }
        } else {
            failure?(NSError(message: "Data in remote notification is not valid."))
        }
    }
    
    func sendTyping(typing: Bool, wrap: Wrap) {
        setActivity(wrap, type: .Typing, inProgress: typing)
    }
    
    func setActivity(wrap: Wrap?, type: UserActivityType, inProgress: Bool, info: [String:AnyObject]? = nil) {
        guard let wrap = wrap else { return }
        var _info = info ?? [String:AnyObject]()
        _info["type"] = type.rawValue
        _info["in_progress"] = inProgress
        let state = [ "activity" : _info ]
        PubNub.sharedInstance.setState(state, forUUID: User.uuid(), onChannel: wrap.uid, withCompletion: nil)
    }
    
    // MARK: - EntryNotifier
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        subscribe(entry as? User)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry == User.currentUser
    }
    
    // MARK: - PNObjectEventListener
    
    func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        if message.data.subscribedChannel == groupName {
            didReceiveMessage(message)
        } else {
            liveSubscription?.didReceiveMessage(message)
        }
        #if DEBUG
            if let msg = message.data.message {
                print("listener didReceiveMessage in \(message.data.actualChannel ?? message.data.subscribedChannel)\n \(msg)")
            }
        #endif
    }
    
    func client(client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        if event.data.subscribedChannel == groupName {
            didReceivePresenceEvent(event)
        } else {
            liveSubscription?.didReceivePresenceEvent(event)
        }
        
        #if DEBUG
            print("PUBNUB - did receive presence event in \(event.data.actualChannel ?? event.data.subscribedChannel)\n: \(event.data)")
        #endif
    }
    
    func client(client: PubNub, didReceiveStatus status: PNStatus) {
        #if DEBUG
            print("PUBNUB - subscribtion status: \(status.debugDescription)")
        #endif
    }
    
    private let additionQueue = RunQueue(limit: 1)
    
    private func didReceiveMessage(message: PNMessageResult) {
        if let notification = notificationFromMessage(message.data, isHistorycal: false) {
            if notification.type.isAddition() {
                additionQueue.run({ (finish) in
                    Logger.log("Fetching notification \(notification)")
                    notification.handle({ _ in
                        NotificationCenter.addHandledNotifications([notification])
                        Logger.log("Fetching notification success \(notification)")
                        finish()
                        }, failure: { error in
                            Logger.log("Fetching notification error \(notification): \(error ?? "")")
                            finish()
                    })
                })
            } else {
                handleNotification(notification)
            }
        }
    }
    
    private func didReceivePresenceEvent(event: PNPresenceEventResult) {
        let data = event.data
        let event = data.presenceEvent
        guard let uuid = data.presence.uuid where uuid != User.uuid() else { return }
        guard let result = PubNub.parseUUID(uuid) else { return }
        let user = result.user
        let device = result.device
        
        if event == "state-change" {
            device.isActive = true
            guard let wrap = Wrap.entry(data.actualChannel) else { return }
            device.activity.handleState(data.presence.state, wrap: wrap)
            if device.activity.type == .Live {
                if device.activity.inProgress {
                    user.fetchIfNeeded({ _ in
                        let broadcast = device.activity.generateLiveBroadcast()
                        wrap.addBroadcast(broadcast)
                        if broadcast.broadcaster?.current == false {
                            Dispatch.mainQueue.async({ [weak broadcast] () in
                                if let broadcast = broadcast {
                                    InAppNotification.showLiveBroadcast(broadcast)
                                }
                            })
                        }
                        }, failure: nil)
                } else {
                    for broadcast in wrap.liveBroadcasts where broadcast.broadcaster == user {
                        wrap.removeBroadcast(broadcast)
                        break
                    }
                }
            }
        } else if event == "join" {
            device.isActive = true
        } else if event == "timeout" || event == "leave" {
            device.isActive = false
            guard let wrap = Wrap.entry(data.actualChannel, allowInsert: false) else { return }
            if device.activity.inProgress && device.activity.wrap == wrap {
                device.activity.inProgress = false
                device.activity.notifyIfNeeded()
                if device.activity.type == .Live {
                    for broadcast in wrap.liveBroadcasts where broadcast.broadcaster == user {
                        wrap.removeBroadcast(broadcast)
                        break
                    }
                }
            }
        }
    }
    
    private func channelActivities(uuids: [[String:AnyObject]]) -> (activities: [String:[String:AnyObject]], users: Set<String>) {
        var activities = [String:[String:AnyObject]]()
        var users = Set<String>()
        for uuid in uuids {
            guard let uid = uuid["uuid"] as? String where uid != User.uuid() else { continue }
            users.insert(uid)
            if let state = uuid["state"] as? [String:AnyObject] {
                if let activity = state["activity"] as? [String:AnyObject] where activity["in_progress"] as? Bool == true {
                    activities[uid] = activity
                }
            }
        }
        return (activities, users)
    }
    
    func refreshUserActivities(notify: Bool = false, completionHandler: (Void -> Void)?) {
        PubNub.sharedInstance.hereNowForChannelGroup(groupName) { (result, status) -> Void in
            if let channels = result?.data.channels {
                
                var users = Set<String>()
                var activities = [String:[String:[String:AnyObject]]]()
                
                for (channel, data) in channels {
                    guard let uuids = data["uuids"] as? [[String:AnyObject]] else { continue }
                    let result = self.channelActivities(uuids)
                    users = users.union(result.users)
                    if !result.activities.isEmpty {
                        activities[channel] = result.activities
                    }
                }
                
                var usersOnline = [User]()
                
                usersLoop: for uuid in users {
                    guard let result = PubNub.parseUUID(uuid) else { continue usersLoop }
                    let user = result.user
                    let device = result.device
                    usersOnline.append(user)
                    device.isActive = true
                    activitiesLoop: for (channel, _activities) in activities {
                        if let activity = _activities[uuid] {
                            device.activity.handleActivity(activity)
                            let wrap = Wrap.entry(channel)
                            device.activity.wrap = wrap
                            if device.activity.inProgress && device.activity.type == .Live {
                                let broadcast = device.activity.generateLiveBroadcast()
                                wrap?.addBroadcastIfNeeded(broadcast, notify: notify)
                            }
                            continue usersLoop
                        }
                    }
                    if device.activity.inProgress {
                        device.activity.wrap?.removeBroadcastFrom(user, notify: notify)
                        device.activity.clear()
                    }
                }
                
                User.currentUser?.wraps.all({ (wrap) in
                    for user in wrap.contributors where !usersOnline.contains(user) {
                        user.devices.all { $0.isActive = false }
                    }
                })
            }
            completionHandler?()
        }
    }
    
    func refreshWrapUserActivities(wrap: Wrap, completionHandler: (Void -> Void)?) {
        PubNub.sharedInstance.hereNowForChannel(wrap.uid, withVerbosity: .State) { (result, status) -> Void in
            
            if let uuids = result?.data.uuids as? [[String:AnyObject]] {
                
                let result = self.channelActivities(uuids)
                
                var usersOnline = [User]()
                
                for uuid in result.users {
                    guard let uuidResult = PubNub.parseUUID(uuid) else { continue }
                    let user = uuidResult.user
                    let device = uuidResult.device
                    usersOnline.append(user)
                    device.isActive = true
                    if let activity = result.activities[uuid] {
                        device.activity.handleActivity(activity)
                        device.activity.wrap = wrap
                        if device.activity.inProgress && device.activity.type == .Live {
                            let broadcast = device.activity.generateLiveBroadcast()
                            wrap.addBroadcastIfNeeded(broadcast)
                        }
                        continue
                    }
                    if device.activity.inProgress && device.activity.wrap == wrap {
                        wrap.removeBroadcastFrom(user)
                        device.activity.clear()
                    }
                }
                
                for user in wrap.contributors where !usersOnline.contains(user) {
                    user.devices.all { $0.isActive = false }
                }
            }
            completionHandler?()
        }
    }
}