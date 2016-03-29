//
//  NotificationSubscription.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/15/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import PubNub

protocol NotificationSubscriptionDelegate: class {
    func notificationSubscription(subscription: NotificationSubscription, didReceiveMessage message: PNMessageResult)
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult)
}

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
    
    func send(message: [NSObject : AnyObject]) {
        PubNub.sharedInstance.publish(message, toChannel: name, withCompletion: nil)
    }
    
    func changeState(state: [String : AnyObject], channel: String) {
        let uuid = PubNub.sharedInstance.currentConfiguration().uuid
        PubNub.sharedInstance.setState(state, forUUID: uuid, onChannel: channel, withCompletion: nil)
    }
    
    func changeState(state: [String : AnyObject]) {
        changeState(state, channel: name)
    }
    
    func hereNow(completion: [[NSObject : AnyObject]]? -> Void) {
        PubNub.sharedInstance.hereNowForChannel(name, withVerbosity: .State) { (result, status) -> Void in
            completion(result?.data.uuids as? [[NSObject : AnyObject]])
        }
    }
    
    func history() -> [AnyObject] {
        let pubnub = PubNub.sharedInstance
        if isGroup {
            return pubnub.channelsForGroup(name).reduce([AnyObject](), combine: { $0 + pubnub.allHistoryFor($1) })
        } else {
            return pubnub.allHistoryFor(name)
        }
    }
}

extension NotificationSubscription: PNObjectEventListener {
    
    func didReceiveMessage(message: PNMessageResult) {
        delegate?.notificationSubscription(self, didReceiveMessage: message)
    }
    
    func didReceivePresenceEvent(event: PNPresenceEventResult) {
        delegate?.notificationSubscription(self, didReceivePresenceEvent: event)
    }
    
    func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        if message.data.actualChannel == name || message.data.subscribedChannel == name {
            didReceiveMessage(message)
        }
    }
    func client(client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        if event.data.actualChannel == name || event.data.subscribedChannel == name {
            didReceivePresenceEvent(event)
        }
    }
}