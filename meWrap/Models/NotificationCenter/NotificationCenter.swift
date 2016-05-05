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

final class NotificationCenter: NSObject {
    
    static let defaultCenter = specify(NotificationCenter()) {
        Network.sharedNetwork.addReceiver($0)
        User.notifier().addReceiver($0)
    }
    
    var enqueuedMessages = [AnyObject]()
    
    var userSubscription = NotificationSubscription(name:"", isGroup:true, observePresence:true)
    weak var liveSubscription: NotificationSubscription?
    
    var pushToken: String?
    var pushTokenData: NSData?
    
    func applicationDidBecomeActive() {
        liveSubscription?.subscribe()
        subscribe()
        Dispatch.mainQueue.after(0.5, block: { self.requestHistory() })
        refreshUserActivities(true, completionHandler: nil)
    }
    
    func handleDeviceToken(deviceToken: NSData) {
        pushTokenData = deviceToken
        pushToken = deviceToken.serializeDevicePushToken()
        if Authorization.active {
            API.updateDevice().send()
        }
    }
    
    func subscribe(user: User? = User.currentUser) {
        guard let user = user else { return }
        let uuid = user.uid
        if uuid.isEmpty { return }
        let channelName = "cg-\(uuid)"
        if userSubscription.name != channelName {
            userSubscription.name = channelName
            userSubscription.delegate = self
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
        userSubscription.subscribe()
        Logger.logglyDestination.userid = User.uuid()
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
    
    func notificationsFromMessages(messages: [AnyObject]?, isHistorycal: Bool = true) -> [Notification] {
        guard let messages = messages where !messages.isEmpty else { return [] }
        
        var notifications = [Notification]()
        
        for message in messages {
            guard let n = Notification.notificationWithMessage(message) else { continue }
            n.isHistorycal = isHistorycal
            guard n.canBeHandled() && !NotificationCenter.canSkipNotification(n) else { continue }
            notifications.append(n)
        }
        
        if notifications.isEmpty { return notifications }
        
        NotificationCenter.addHandledNotifications(notifications)
        
        return notifications
    }
    
    func requestHistory() {
        RunQueue.fetchQueue.run { [unowned self] finish in
            
            guard !self.userSubscription.name.isEmpty && Network.sharedNetwork.reachable else {
                finish()
                return
            }
            
            Dispatch.defaultQueue.async({
                let messages = self.userSubscription.history()
                Dispatch.mainQueue.async({
                    if messages.count > 0 {
                        self.handleNotifications(self.notificationsFromMessages(messages))
                    }
                    finish()
                })
            })
        }
    }
    
    private func handleNotifications(notifications: [Notification]) {
        if !notifications.isEmpty {
            for notification in notifications {
                RunQueue.fetchQueue.run { finish in
                    notification.fetch({ _ in
                        finish()
                        }, failure: { _ in
                            finish()
                    })
                }
                Logger.log("PubNub message received \(notification)")
            }
            
            RunQueue.fetchQueue.run { finish in
                for notification in notifications {
                    notification.submit()
                }
                finish()
            }
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
    
    func handleEnqueuedMessages() {
        let notifications = notificationsFromMessages(enqueuedMessages, isHistorycal: false)
        enqueuedMessages.removeAll()
        handleNotifications(notifications)
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
}

extension NotificationCenter: NetworkNotifying {
    func networkDidChangeReachability(network: Network) {
        if network.reachable {
            requestHistory()
            refreshUserActivities(true, completionHandler: nil)
        }
    }
}

extension NotificationCenter: PNObjectEventListener {
    
    func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        userSubscription.didReceiveMessage(message)
        liveSubscription?.didReceiveMessage(message)
        #if DEBUG
            if let msg = message.data.message {
                print("listener didReceiveMessage in \(message.data.actualChannel ?? message.data.subscribedChannel)\n \(msg)")
            }
        #endif
    }
    
    func client(client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        userSubscription.didReceivePresenceEvent(event)
        liveSubscription?.didReceivePresenceEvent(event)
        #if DEBUG
            print("PUBNUB - did receive presence event in \(event.data.actualChannel ?? event.data.subscribedChannel)\n: \(event.data)")
        #endif
    }
    
    func client(client: PubNub, didReceiveStatus status: PNStatus) {
        #if DEBUG
            print("PUBNUB - subscribtion status: \(status.debugDescription)")
        #endif
        if UIApplication.sharedApplication().applicationState == .Active && status.category == .PNConnectedCategory {
            if let status = status as? PNSubscribeStatus where status.subscribedChannelGroups.count > 0 {
                requestHistory()
            }
        }
    }
}

extension NotificationCenter: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        subscribe(entry as? User)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry == User.currentUser
    }
}

extension NotificationCenter: NotificationSubscriptionDelegate {
    
    func notificationSubscription(subscription: NotificationSubscription, didReceiveMessage message: PNMessageResult) {
        enqueuedMessages.append(message.data)
        enqueueSelector(#selector(self.handleEnqueuedMessages))
    }
    
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult) {
        let data = event.data
        let event = data.presenceEvent
        guard let uuid = data.presence.uuid where uuid != User.uuid() else { return }
        guard let result = PubNub.parseUUID(uuid) else { return }
        let user = result.user
        let device = result.device
        
        if event == "timeout" || event == "leave" {
            device.isActive = false
        } else if event == "join" {
            device.isActive = true
        }
        
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
                            EntryToast.showLiveBroadcast(broadcast)
                        }
                        }, failure: nil)
                } else {
                    for broadcast in wrap.liveBroadcasts where broadcast.broadcaster == user {
                        wrap.removeBroadcast(broadcast)
                        break
                    }
                }
            }
        } else if event == "timeout" || event == "leave" {
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
        PubNub.sharedInstance.hereNowForChannelGroup(userSubscription.name) { (result, status) -> Void in
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