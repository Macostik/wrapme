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
    case Typing = 1, Streaming
}

class UserActivity: NSObject {
    
    var inProgress = false
    
    weak var user: User?
    
    let type: UserActivityType
    
    let info: [String:AnyObject]
    
    required init(type: UserActivityType, info: [String:AnyObject], user: User) {
        self.user = user
        self.type = type
        self.info = info
        super.init()
        self.inProgress = info["in_progress"] as? Bool ?? false
    }
    
    convenience init?(uuid: String?, state: [NSObject:AnyObject]?) {
        guard let user = PubNub.userFromUUID(uuid) else { return nil }
        guard let info = state?["activity"] as? [String:AnyObject] else { return nil }
        guard let type = info["type"] as? Int else { return nil }
        guard let activityType = UserActivityType(rawValue: type) else { return nil }
        self.init(type: activityType, info: info, user: user)
    }
}
