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
    case None = 0, Typing, Streaming
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
            self.info = info
            if let type = info["type"] as? Int, let activityType = UserActivityType(rawValue: type) {
                self.type = activityType
                inProgress = info["in_progress"] as? Bool ?? false
                if inProgress {
                    self.wrap = wrap
                }
            }
        }
    }
}
