//
//  PubNub+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/3/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import PubNub

extension PubNub {
    
    private static var _sharedInstance: PubNub?
    
    static var sharedInstance: PubNub! {
        get {
            if _sharedInstance == nil {
                guard User.currentUser != nil else {
                    return nil
                }
                let configuration: PNConfiguration!
                if Environment.currentEnvironment.isProduction {
                    configuration = PNConfiguration(publishKey: "pub-c-87bbbc30-fc43-4f6b-b1f4-cedd5f30d5e8", subscribeKey: "sub-c-6562fe64-4270-11e4-aed8-02ee2ddab7fe")
                } else {
                    configuration = PNConfiguration(publishKey: "pub-c-16ba2a90-9331-4472-b00a-83f01ff32089", subscribeKey: "sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe")
                }
                configuration.uuid = User.channelName()
                PNLog.enabled(false)
                _sharedInstance = clientWithConfiguration(configuration)
            }
            return _sharedInstance!
        }
        set {
            _sharedInstance = newValue
        }
    }
    
    class func userFromUUID(uuid: String?) -> User? {
        if let uuid = uuid {
            if uuid.containsString("-") {
                return User.entry(uuid.componentsSeparatedByString("-").first)
            } else {
                return User.entry(uuid)
            }
        } else {
            return nil
        }
    }
}

extension NSDate {
    
    private static var TimetokenPrecisionMultiplier: NSTimeInterval = 10000000.0
    
    class func dateWithTimetoken(timetoken: NSNumber) -> NSDate {
        return NSDate(timeIntervalSince1970:timetoken.doubleValue / TimetokenPrecisionMultiplier)
    }
    
    func timetoken() -> NSNumber {
        return NSNumber(double: timeIntervalSince1970 * NSDate.TimetokenPrecisionMultiplier)
    }
}

@objc protocol NotificationSubscriptionDelegate {
    optional func notificationSubscription(subscription: NotificationSubscription, didReceiveMessage message: PNMessageResult)
    optional func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult)
}

class NotificationSubscription: NSObject {
    weak var delegate: NotificationSubscriptionDelegate?
    
    var name: String
    
    var isGroup = false
    
    var observePresence = false
    
    var isSubscribed: Bool {
        return PubNub.sharedInstance.isSubscribedOn(name)
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
        subscribe()
    }
    
    func subscribe() {
        if isSubscribed {
            return
        }
        if isGroup {
            PubNub.sharedInstance.subscribeToChannelGroups([name], withPresence: observePresence)
        } else {
            PubNub.sharedInstance.subscribeToChannels([name], withPresence: observePresence)
        }
    }
    
    func unsubscribe() {
        if !isSubscribed {
            return
        }
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
        if let uuid = PubNub.sharedInstance.currentConfiguration().uuid {
            PubNub.sharedInstance.setState(state, forUUID: uuid, onChannel: channel, withCompletion: nil)
        }
    }
    
    func changeState(state: [NSObject : AnyObject]?) {
        changeState(state, channel: name)
    }
    
    func hereNow(completion: [[NSObject : AnyObject]]? -> Void) {
        PubNub.sharedInstance.hereNowForChannel(name, withVerbosity: .State) { (result, status) -> Void in
            if !(status?.error ?? false) {
                completion(result.data.uuids as? [[NSObject : AnyObject]])
            }
        }
    }
    
    func history(from: NSDate, to: NSDate, success: [[NSObject:AnyObject]]? -> Void, failure: NSError? -> Void) {
        let startDate = from.timetoken()
        let endDate = to.timetoken()
        let pubnub = PubNub.sharedInstance
        if isGroup {
            pubnub.channelsForGroup(name, withCompletion: { (result, status) -> Void in
                if status?.error ?? false {
                    failure(nil)
                } else {
                    if let channels = result?.data?.channels as? [String] where !channels.isEmpty {
                        var fetchedChannels = Set<String>()
                        var messages = [[NSObject : AnyObject]]()
                        for channel in channels {
                            pubnub.historyForChannel(channel, start: startDate, end: endDate, includeTimeToken: true, withCompletion: { (result, status) -> Void in
                                fetchedChannels.insert(channel)
                                if let _messages = result?.data?.messages as? [[NSObject : AnyObject]] {
                                    messages.appendContentsOf(_messages)
                                }
                                if fetchedChannels.count == channels.count {
                                    messages.sortInPlace({ (msg1, msg2) -> Bool in
                                        return (msg1["timetoken"] as? NSNumber)?.doubleValue < (msg2["timetoken"] as? NSNumber)?.doubleValue
                                    })
                                    success(messages)
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
                    success(result.data.messages as? [[NSObject:AnyObject]])
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
        if message.data.actualChannel == name || message.data.subscribedChannel == name {
            didReceiveMessage(message)
        }
    }
    func client(client: PubNub!, didReceivePresenceEvent event: PNPresenceEventResult!) {
        if event.data.actualChannel == name || event.data.subscribedChannel == name {
            didReceivePresenceEvent(event)
        }
    }
}