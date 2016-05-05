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
    
    private static var _sharedInstance: PubNub? {
        willSet {
            newValue?.addListener(NotificationCenter.defaultCenter)
        }
    }
    
    static var sharedInstance: PubNub {
        if var pubnub = _sharedInstance {
            if pubnub.currentConfiguration().uuid != User.uuid() {
                let configuration = defaultConfiguration()
                pubnub = pubnub.copyWithConfiguration(configuration, completion: { _ in })
                _sharedInstance = pubnub
            }
            return pubnub
        }
        let configuration = defaultConfiguration()
        let pubnub = clientWithConfiguration(configuration)
        _sharedInstance = pubnub
        return pubnub
    }
    
    class func releaseSharedInstance() {
        _sharedInstance = nil
    }
    
    class func defaultConfiguration() -> PNConfiguration {
        let keys = Environment.current.pubnub
        let configuration = PNConfiguration(publishKey: keys.publishKey, subscribeKey: keys.subscribeKey)
        configuration.catchUpOnSubscriptionRestore = false
        configuration.uuid = User.uuid()
        configuration.presenceHeartbeatInterval = 30
        configuration.presenceHeartbeatValue = 60
        return configuration
    }
    
    class func userUIDFromUUID(uuid: String?) -> String? {
        if let uuid = uuid {
            if uuid.containsString("-") {
                return uuid.componentsSeparatedByString("-").first
            } else {
                return uuid
            }
        } else {
            return nil
        }
    }
    
    class func userFromUUID(uuid: String?) -> User? {
        return User.entry(userUIDFromUUID(uuid))
    }
    
    class func parseUUID(uuid: String?) -> (user: User, device: Device)? {
        guard let uuid = uuid where uuid.containsString("-") else { return nil }
        let uids = uuid.componentsSeparatedByString("-")
        guard uids.count >= 2 else { return nil }
        guard let user = User.entry(uids[0]) else { return nil }
        guard let device = Device.entry(uids[1]) else { return nil }
        if !user.devices.contains(device) {
            user.devices.insert(device)
        }
        return (user, device)
    }
    
    func allHistoryFor(channel: String) -> [AnyObject] {
        var messages = [AnyObject]()
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var historyDates = userDefaults.historyDates
        let historyDate = historyDates[channel] ?? userDefaults.historyDate?.timeIntervalSince1970
        guard var start: NSNumber = historyDate else {
            historyDates[channel] = NSDate.now().timeIntervalSince1970
            userDefaults.historyDates = historyDates
            return messages
        }
        
        var _result = historyFor(channel, start: start, end: nil, reverse: true)
        while let result = _result where result.data.messages.count > 0 {
            Logger.log("PUBNUB - received history for: \(channel) since: \(start), count: \(result.data.messages.count)")
            messages.appendContentsOf(result.data.messages)
            start = result.data.end
            _result = historyFor(channel, start: start, end: nil, reverse: true)
        }
        if _result != nil {
            historyDates[channel] = start
            userDefaults.historyDates = historyDates
        }
        return messages
    }
    
    func historyFor(channel: String, start: NSNumber?, end: NSNumber?, reverse: Bool = false) -> PNHistoryResult? {
        return Dispatch.sleep({ (awake) in
            historyForChannel(channel, start: start, end: end, limit: 100, reverse: reverse) { (result, _) in
                awake(result)
            }
        })
    }
    
    func channelsForGroup(group: String) -> [String] {
        return Dispatch.sleep({ (awake) in
            channelsForGroup(group) { result, _ in awake(result?.data.channels) }
        }) ?? []
    }
}

extension NSDate {
    convenience init(timetoken: NSNumber) {
        self.init(timeIntervalSince1970:timetoken.doubleValue / 10000000)
    }
}
