//
//  NotificationSubscription.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/15/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import PubNub

class NotificationSubscription: NSObject {
    weak var delegate: NotificationSubscriptionDelegate?
    
    var name: String
    
    var isGroup = false
    
    var observePresence = false
    
    var isSubscribed: Bool {
        return PubNub.sharedInstance.isSubscribedOn(name) ?? false
    }
    
    deinit {
        unsubscribe()
    }
    
    init(name: String, isGroup: Bool, observePresence: Bool) {
        self.name = name
        self.isGroup = isGroup
        self.observePresence = observePresence
        super.init()
        PubNub.sharedInstance.addListener(self)
    }
    
    func subscribe() {
        if isGroup {
            PubNub.sharedInstance.subscribeToChannelGroups([name], withPresence: observePresence)
        } else {
            PubNub.sharedInstance.subscribeToChannels([name], withPresence: observePresence)
        }
    }
    
    func unsubscribe() {
        if isGroup {
            PubNub.sharedInstance.unsubscribeFromChannelGroups([name], withPresence: observePresence)
        } else {
            PubNub.sharedInstance.unsubscribeFromChannels([name], withPresence: observePresence)
        }
    }
    
    func send(message: [NSObject : AnyObject]?) {
        PubNub.sharedInstance.publish(message, toChannel: name, withCompletion: nil)
    }
    
    func changeState(state: [NSObject : AnyObject]?, channel: String) {
        if let uuid = PubNub.sharedInstance.currentConfiguration()?.uuid {
            PubNub.sharedInstance.setState(state, forUUID: uuid, onChannel: channel, withCompletion: nil)
        }
    }
    
    func changeState(state: [NSObject : AnyObject]?) {
        changeState(state, channel: name)
    }
    
    func hereNow(completion: [[NSObject : AnyObject]]? -> Void) {
        PubNub.sharedInstance.hereNowForChannel(name, withVerbosity: .State) { (result, status) -> Void in
            completion(result?.data?.uuids as? [[NSObject : AnyObject]])
        }
    }
    
    func history(from: NSDate, to: NSDate, success: [[NSObject:AnyObject]] -> Void, failure: NSError? -> Void) {
        let startDate = from.timestamp
        let endDate = to.timestamp
        let pubnub = PubNub.sharedInstance
        if isGroup {
            pubnub.channelsForGroup(name, withCompletion: { (result, status) -> Void in
                if status?.error ?? false {
                    failure(nil)
                } else {
                    if let channels = result?.data?.channels as? [String] where !channels.isEmpty {
                        var fetchedChannels = 0
                        let messages = NSMutableArray()
                        for channel in channels {
                            pubnub.historyForChannel(channel, start: startDate, end: endDate, includeTimeToken: true, withCompletion: { (result, status) -> Void in
                                fetchedChannels++
                                if let _messages = result?.data?.messages {
                                    messages.addObjectsFromArray(_messages)
                                }
                                if fetchedChannels == channels.count {
                                    messages.sortUsingDescriptors([NSSortDescriptor(key: "timetoken", ascending: true)])
                                    success(NSArray(array: messages) as? [[NSObject:AnyObject]] ?? [])
                                }
                            })
                        }
                    } else {
                        success([])
                    }
                }
            })
        } else {
            pubnub.historyForChannel(name, start: startDate, end: endDate, includeTimeToken: true, withCompletion: { (result, status) -> Void in
                if status?.error ?? false {
                    failure(nil)
                } else {
                    success(result?.data?.messages as? [[NSObject:AnyObject]] ?? [])
                }
            })
        }
    }
}

extension NotificationSubscription: PNObjectEventListener {
    
    func didReceiveMessage(message: PNMessageResult) {
        delegate?.notificationSubscription?(self, didReceiveMessage: message)
    }
    
    func didReceivePresenceEvent(event: PNPresenceEventResult) {
        delegate?.notificationSubscription?(self, didReceivePresenceEvent: event)
    }
    
    func client(client: PubNub!, didReceiveMessage message: PNMessageResult!) {
        if message?.data?.actualChannel == name || message?.data?.subscribedChannel == name {
            didReceiveMessage(message)
        }
    }
    func client(client: PubNub!, didReceivePresenceEvent event: PNPresenceEventResult!) {
        if event?.data?.actualChannel == name || event?.data?.subscribedChannel == name {
            didReceivePresenceEvent(event)
        }
    }
}