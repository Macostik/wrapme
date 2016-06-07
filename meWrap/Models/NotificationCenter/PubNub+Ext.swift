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
    
    func allHistoryForChannelGroup(group: String, completionHandler: [AnyObject] -> ()) {
        
        var allMessages = [AnyObject]()
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var historyDates = userDefaults.historyDates
        
        channelsForGroup(group) { (result, status) in
            if let channels = result?.data.channels {
                
                var handled = channels.count
                
                let handle = {
                    handled = handled - 1
                    if handled == 0 {
                        userDefaults.historyDates = historyDates
                        completionHandler(allMessages)
                    }
                }
                
                for channel in channels {
                    let historyDate = historyDates[channel] ?? userDefaults.historyDate?.timeIntervalSince1970
                    guard let start: NSNumber = historyDate else {
                        historyDates[channel] = NSDate.now().timeIntervalSince1970
                        handle()
                        continue
                    }
                    
                    Logger.log("PUBNUB - history query start for: \(channel) since: \(start)")
                    self.recursiveHistoryFor(channel, start: start, completionHandler: { (messages, start) in
                        if messages.isEmpty {
                            Logger.log("PUBNUB - history query end for: \(channel) since: \(start)")
                            historyDates[channel] = start
                            handle()
                        } else {
                            Logger.log("PUBNUB - history query messages for: \(channel) since: \(start), count: \(messages.count)")
                            allMessages.appendContentsOf(messages)
                        }
                    })
                }
                
            } else {
                completionHandler(allMessages)
            }
        }
    }
    
    private func recursiveHistoryFor(channel: String, start: NSNumber?, completionHandler: ([AnyObject], NSNumber?) -> ()) {
        historyForChannel(channel, start: start, end: nil, limit: 100, reverse: true) { (result, _) in
            if let result = result, case let messages = result.data.messages where !messages.isEmpty {
                completionHandler(messages, start)
                self.recursiveHistoryFor(channel, start: result.data.end, completionHandler: completionHandler)
            } else {
                completionHandler([], start)
            }
        }
    }
}

extension NSDate {
    convenience init(timetoken: NSNumber) {
        self.init(timeIntervalSince1970:timetoken.doubleValue / 10000000)
    }
}
