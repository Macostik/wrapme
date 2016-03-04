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
    
    var inProgress = false {
        didSet {
            if inProgress != oldValue {
                Dispatch.mainQueue.async({ self.user?.notifyOnUpdate(.UserStatus) })
            }
        }
    }
    
    weak var user: User?
    
    weak var wrap: Wrap?
    
    var type: UserActivityType = .None
    
    var info = [String:AnyObject]()
    
    init(user: User) {
        self.user = user
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
        if let type = info["type"] as? Int, let activityType = UserActivityType(rawValue: type) {
            self.type = activityType
            inProgress = info["in_progress"] as? Bool ?? false
        }
    }
    
    mutating func clear() {
        inProgress = false
        info = [String:AnyObject]()
        wrap = nil
    }
    
    func generateLiveBroadcast() -> LiveBroadcast {
        let broadcast = LiveBroadcast()
        broadcast.broadcaster = user
        broadcast.wrap = wrap
        broadcast.title = info["title"] as? String
        broadcast.streamName = info["streamName"] as? String ?? ""
        return broadcast
    }
}
