//
//  UserActivity.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/8/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

enum UserActivityType: Int {
    case None = 0, Typing, Live, Photo, Video
}

struct UserActivity {
    
    private var needsNotify = false
    
    var inProgress = false {
        didSet {
            if inProgress != oldValue {
                if inProgress {
                    device?.activeAt = NSDate.now()
                }
                needsNotify = true
            }
        }
    }
    
    mutating func notifyIfNeeded() {
        if needsNotify {
            needsNotify = false
            Dispatch.mainQueue.async({ self.device?.owner?.notifyOnUpdate(.UserStatus) })
        }
    }
    
    weak var device: Device?
    
    weak var wrap: Wrap?
    
    var type: UserActivityType = .None {
        didSet {
            if type != oldValue {
                needsNotify = true
            }
        }
    }
    
    var info = [String:AnyObject]()
    
    init(device: Device) {
        self.device = device
    }
    
    mutating func handleState(state: [NSObject:AnyObject]?, wrap: Wrap?) {
        if let info = state?["activity"] as? [String:AnyObject] {
            handleActivity(info)
            if inProgress {
                self.wrap = wrap
            }
        }
    }
    
    mutating func handleActivity(info: [String:AnyObject]) {
        self.info = info
        if let _type = info["type"], let type = Int("\(_type)"), let activityType = UserActivityType(rawValue: type) {
            self.type = activityType
            inProgress = info["in_progress"] as? Bool ?? false
        }
        notifyIfNeeded()
    }
    
    mutating func clear() {
        inProgress = false
        info = [String:AnyObject]()
        wrap = nil
        notifyIfNeeded()
    }
    
    func generateLiveBroadcast() -> LiveBroadcast {
        let broadcast = LiveBroadcast()
        broadcast.broadcaster = device?.owner
        broadcast.wrap = wrap
        broadcast.title = info["title"] as? String
        broadcast.streamName = info["streamName"] as? String ?? ""
        return broadcast
    }
}
