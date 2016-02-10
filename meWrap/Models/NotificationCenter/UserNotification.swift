//
//  UserNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class UserUpdateNotification: Notification {
    
    var user: User?
    
    internal override func setup(body: [String:AnyObject]) {
        super.setup(body)
        createDescriptor(User.self, body: body, key: "user")
    }
    
    internal override func createEntry(descriptor: EntryDescriptor) {
        user = getEntry(User.self, descriptor: descriptor, mapper: {
            Authorization.current.updateWithUserData($1)
            $0.map($1)
        })
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if let user = user where Authorization.active {
            user.recursivelyFetchIfNeeded(success, failure: failure)
        } else {
            success()
        }
    }
    
    override func submit() {
        user?.notifyOnUpdate(.Default)
    }
    
    override func canBeHandled() -> Bool { return !originatedByCurrentUser }
}