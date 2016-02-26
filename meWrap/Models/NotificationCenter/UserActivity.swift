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
    
    var inProgress = false
    
    weak var user: User?
    
    var type: UserActivityType = .None
    
    var info = [String:AnyObject]()
    
    init(user: User) {
        self.user = user
    }
    
    mutating func handleState(state: [NSObject:AnyObject]?) {
        if let info = state?["activity"] as? [String:AnyObject] {
            self.info = info
            if let type = info["type"] as? Int, let activityType = UserActivityType(rawValue: type) {
                self.type = activityType
                self.inProgress = info["in_progress"] as? Bool ?? false
            }
        }
    }
}
