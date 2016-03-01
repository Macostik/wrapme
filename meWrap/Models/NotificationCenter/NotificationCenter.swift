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
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt(byte))
        }
        return hexString
    }
}

class NotificationCenter: NSObject {
    
    static let defaultCenter = NotificationCenter()
    
    var enqueuedMessages = [AnyObject]()
    
    var userSubscription = NotificationSubscription(name:"", isGroup:true, observePresence:true)
    
    var pushToken: String?
    
    override init() {
        super.init()
        Dispatch.mainQueue.after(0.2, block: { [weak self] _ in
            NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object:nil, queue:NSOperationQueue.mainQueue(), usingBlock:{ _ in
                Dispatch.mainQueue.after(0.5, block: { self?.requestHistory() })
            })
            })
    }
    
    func configure() {
        PubNub.sharedInstance.addListener(self)
        User.notifier().addReceiver(self)
    }
    
    func handleDeviceToken(deviceToken: NSData) {
        pushToken = deviceToken.serializeDevicePushToken()
        if Authorization.active {
            APIRequest.updateDevice().send()
        }
    }
    
    func subscribe() {
        if let user = User.currentUser {
            subscribeWithUser(user)
        }
    }
    
    func subscribeWithUser(user: User) {
        let uuid = user.uid
        if uuid.isEmpty { return }
        let channelName = "cg-\(uuid)"
        if userSubscription.name != channelName {
            userSubscription.name = channelName
            userSubscription.delegate = self
            if pushToken != nil {
                if Authorization.active {
                    APIRequest.updateDevice().send()
                }
            } else {
                UIApplication.sharedApplication().registerForRemoteNotifications()
            }
        }
        PubNub.sharedInstance.subscribeToChannels([User.channelName()], withPresence: false)
        userSubscription.subscribe()
    }
    
    func clear() {
        userSubscription.unsubscribe()
        NSUserDefaults.standardUserDefaults().clearHandledNotifications()
        NSUserDefaults.standardUserDefaults().historyDate = nil
    }
    
    func addHandledNotifications(notifications: [Notification]) {
        
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
    
    func canSkipNotification(notification: Notification) -> Bool {
        if let uid = notification.uid {
            return NSUserDefaults.standardUserDefaults().handledNotifications.contains(uid) ?? false
        } else {
            return true
        }
    }
    
    func notificationsFromMessages(messages: [AnyObject]?) -> [Notification] {
        guard let messages = messages where !messages.isEmpty else { return [] }
        
        var notifications = [Notification]()
        
        for message in messages {
            guard let n = Notification.notificationWithMessage(message) else { continue }
            guard n.canBeHandled() && !canSkipNotification(n) else { continue }
            notifications.append(n)
        }
        
        if notifications.isEmpty { return notifications }
        
        addHandledNotifications(notifications)
        
        return notifications.sort({ $0.publishedAt < $1.publishedAt })
    }
    
    func requestHistory() {
        RunQueue.fetchQueue.run { [unowned self] finish in
            
            guard Network.sharedNetwork.reachable && !self.userSubscription.name.isEmpty else {
                finish()
                return
            }
            
            let userDefaults = NSUserDefaults.standardUserDefaults()
            guard let fromDate = userDefaults.historyDate else {
                NSUserDefaults.standardUserDefaults().historyDate = NSDate.now()
                finish()
                return
            }
            let toDate = NSDate.now()
            
            self.userSubscription.history(fromDate, to: toDate, success: { (messages) -> Void in
                if messages.count > 0 {
                    Logger.log("PUBNUB - received history starting from: \(fromDate) to: \(toDate)")
                    self.handleNotifications(self.notificationsFromMessages(messages))
                    if let timetoken = messages.last?["timetoken"] as? NSNumber {
                        userDefaults.historyDate = NSDate(timetoken: timetoken).dateByAddingTimeInterval(0.001)
                        self.requestHistory()
                    } else {
                        userDefaults.historyDate = toDate
                    }
                } else {
                    userDefaults.historyDate = toDate
                }
                finish()
                }, failure: { _ in finish() })
        }
    }
    
    private func handleNotifications(notifications: [Notification]) {
        if !notifications.isEmpty {
            var playedSoundTypes = Set<Sound>()
            for notification in notifications {
                RunQueue.fetchQueue.run { finish in
                    notification.fetch({ _ in
                        if !playedSoundTypes.contains(notification.soundType()) {
                            SoundPlayer.player.playForNotification(notification)
                        }
                        playedSoundTypes.insert(notification.soundType())
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
    
    func handleRemoteNotification(data: [String:AnyObject]?, success: Notification -> Void, failure: FailureBlock?) {
        guard let data = data else  {
            failure?(nil)
            return
        }
        
        if let notification = Notification.notificationWithBody(data, publishedAt:nil) {
            Logger.log("APNS received: \(notification.description)")
            if canSkipNotification(notification) {
                success(notification)
            } else {
                RunQueue.fetchQueue.run { finish in
                    _ = try? EntryContext.sharedContext.save()
                    notification.handle({ () -> Void in
                        self.addHandledNotifications([notification])
                        success(notification)
                        finish()
                        }, failure: { (error) -> Void in
                            failure?(error)
                            finish()
                    })
                }
            }
        } else {
            failure?(NSError(message: "Data in remote notification is not valid."))
        }
    }
    
    func handleEnqueuedMessages() {
        let notifications = notificationsFromMessages(enqueuedMessages)
        enqueuedMessages.removeAll()
        handleNotifications(notifications)
    }
}

extension NotificationCenter: PNObjectEventListener {
    
    func client(client: PubNub!, didReceiveMessage message: PNMessageResult!) {
        #if DEBUG
            print("listener didReceiveMessage \(message.data.message)")
        #endif
    }
    
    func client(client: PubNub!, didReceivePresenceEvent event: PNPresenceEventResult!) {
        print("PUBNUB - did receive presence event: \(event.data.presenceEvent)")
    }
    
    func client(client: PubNub!, didReceiveStatus status: PNStatus!) {
        print("PUBNUB - subscribtion status: \(status.debugDescription)")
        if status?.category == .PNConnectedCategory {
            if let status = status as? PNSubscribeStatus where status.subscribedChannelGroups?.count > 0 {
                requestHistory()
            }
        }
    }
}

extension NotificationCenter: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        if let user = entry as? User {
            subscribeWithUser(user)
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry == User.currentUser
    }
}

extension NotificationCenter: NotificationSubscriptionDelegate {
    
    func notificationSubscription(subscription: NotificationSubscription, didReceiveMessage message: PNMessageResult) {
        enqueuedMessages.append(message.data)
        enqueueSelector("handleEnqueuedMessages")
    }
    
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult) {
        guard let data = event.data, let event = data.presenceEvent else { return }
        guard let uuid = data.presence?.uuid where uuid != User.channelName() else { return }
        guard let user = PubNub.userFromUUID(uuid) else { return }
        
        if event == "timeout" || event == "leave" {
            user.isActive = false
        } else if event == "join" {
            user.isActive = true
        }
        
        user.activity.handleState(data.presence?.state)
        
        guard user.activity.type == .Streaming else { return }
        guard let wrap = Wrap.entry(data.actualChannel) else { return }
        if event == "state-change" {
            user.fetchIfNeeded({ _ in
                if user.activity.inProgress {
                    let broadcast = LiveBroadcast()
                    broadcast.broadcaster = user
                    broadcast.wrap = wrap
                    broadcast.title = user.activity.info["title"] as? String
                    broadcast.streamName = user.activity.info["streamName"] as? String ?? ""
                    wrap.addBroadcast(broadcast)
                } else {
                    for broadcast in wrap.liveBroadcasts where broadcast.broadcaster == user {
                        wrap.removeBroadcast(broadcast)
                        break
                    }
                }
                }, failure: nil)
        } else if event == "timeout" || event == "leave" {
            user.activity.inProgress = false
            for broadcast in wrap.liveBroadcasts where broadcast.broadcaster == user {
                wrap.removeBroadcast(broadcast)
                break
            }
        }
    }
    
    private func activeUsers(uuids: [[String:AnyObject]]) -> [User] {
        var users = [User]()
        for uuid in uuids {
            guard let uid = uuid["uuid"] as? String where uid != User.channelName() else { continue }
            guard let user = PubNub.userFromUUID(uid) else { continue }
            user.isActive = true
            if let state = uuid["state"] as? [String:AnyObject] {
                user.activity.handleState(state)
            }
            users.append(user)
            user.fetchIfNeeded(nil, failure: nil)
        }
        return users
    }
    
    private func liveBroadcasts(uuids: [[String:AnyObject]], wrap: Wrap) -> [LiveBroadcast] {
        var broadcasts = [LiveBroadcast]()
        let users = activeUsers(uuids)
        for user in users {
            let activity = user.activity
            if activity.inProgress && activity.type == .Streaming {
                let broadcast = LiveBroadcast()
                broadcast.broadcaster = user
                broadcast.wrap = wrap
                broadcast.title = activity.info["title"] as? String
                broadcast.streamName = activity.info["streamName"] as? String ?? ""
                broadcasts.append(broadcast)
            }
        }
        return broadcasts
    }
    
    func fetchLiveBroadcasts(completionHandler: Void -> Void) {
        PubNub.sharedInstance.hereNowForChannelGroup(userSubscription.name) { (result, status) -> Void in
            if let channels = result?.data?.channels as? [String:[String:AnyObject]] {
                for (channel, data) in channels where channel != "public" {
                    guard let uuids = data["uuids"] as? [[String:AnyObject]] else { continue }
                    guard let wrap = Wrap.entry(channel) else { continue }
                    wrap.liveBroadcasts = self.liveBroadcasts(uuids, wrap: wrap)
                }
            }
            completionHandler()
        }
    }
    
    func fetchLiveBroadcastsForWrap(wrap: Wrap, completionHandler: [LiveBroadcast] -> Void) {
        PubNub.sharedInstance.hereNowForChannel(wrap.uid, withVerbosity: .State) { (result, status) -> Void in
            if let uuids = result?.data?.uuids as? [[String:AnyObject]] {
                completionHandler(self.liveBroadcasts(uuids, wrap: wrap))
            } else {
                completionHandler([])
            }
        }
    }
}