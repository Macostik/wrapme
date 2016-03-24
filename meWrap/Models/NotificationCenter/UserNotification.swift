//
//  UserNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class UserUpdateNotification: EntryNotification<User> {
    
    override func dataKey() -> String { return "user" }
    
    override func mapEntry(user: User, data: [String : AnyObject]) {
        if user.current {
            Authorization.current.updateWithUserData(data)
        }
        user.map(data)
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if let user = _entry where Authorization.active {
            user.recursivelyFetchIfNeeded(success, failure: failure)
        } else {
            success()
        }
    }
    
    override func submit() {
        _entry?.notifyOnUpdate(.Default)
    }
    
    override func canBeHandled() -> Bool { return !originatedByCurrentUser }
}