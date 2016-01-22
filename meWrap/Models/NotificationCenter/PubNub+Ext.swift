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
    
    static var sharedInstance: PubNub {
        if var pubnub = _sharedInstance {
            if pubnub.currentConfiguration().uuid != User.channelName() {
                let configuration = defaultConfiguration()
                pubnub = pubnub.copyWithConfiguration(configuration)
                _sharedInstance = pubnub
            }
            return pubnub
        }
        let configuration = defaultConfiguration()
        PNLog.enabled(false)
        let pubnub = clientWithConfiguration(configuration)
        _sharedInstance = pubnub
        return pubnub
    }
    
    class func defaultConfiguration() -> PNConfiguration {
        let configuration: PNConfiguration!
        if Environment.currentEnvironment.isProduction {
            configuration = PNConfiguration(publishKey: "pub-c-87bbbc30-fc43-4f6b-b1f4-cedd5f30d5e8", subscribeKey: "sub-c-6562fe64-4270-11e4-aed8-02ee2ddab7fe")
        } else {
            configuration = PNConfiguration(publishKey: "pub-c-16ba2a90-9331-4472-b00a-83f01ff32089", subscribeKey: "sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe")
        }
        configuration.uuid = User.channelName()
        return configuration
    }
    
    class func clearSharedInstance() {
        _sharedInstance = nil
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
    convenience init(timetoken: NSNumber) {
        self.init(timeIntervalSince1970:timetoken.doubleValue / 10000000)
    }
}

@objc protocol NotificationSubscriptionDelegate {
    optional func notificationSubscription(subscription: NotificationSubscription, didReceiveMessage message: PNMessageResult)
    optional func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult)
}