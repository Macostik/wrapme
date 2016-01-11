//
//  WrapNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class WrapNotification: Notification {
    
    var wrap: Wrap?
    
    internal override func setup(body: [String:AnyObject]) {
        super.setup(body)
        createDescriptor(Wrap.self, body: body, key: "wrap")
    }
    
    internal override func createEntry(descriptor: EntryDescriptor) {
        self.wrap = getEntry(Wrap.self, descriptor: descriptor, mapper: { $0.map($1) })
    }
}

class ContributorAddNotification: WrapNotification {
    
    override func notifiable() -> Bool {
        guard let contributor = wrap?.contributor else { return false }
        guard let currentUser = User.currentUser else { return false }
        return !contributor.current && user == currentUser && inviter != currentUser
    }
    
    override func soundType() -> Sound { return .s01 }
    
    var user: User?
    
    var inviter: User?
    
    internal override func createEntry(descriptor: EntryDescriptor) {
        super.createEntry(descriptor)
        guard let body = body else { return }
        let userData = body["user"] as? [String: AnyObject]
        user = userData != nil ? User.mappedEntry(userData!) : User.entry(body["user_uid"] as? String)
        if let inviter = body["inviter"] as? [String: AnyObject] {
            self.inviter = User.mappedEntry(inviter)
        }
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        guard let wrap = wrap else {
            success()
            return
        }
        if let user = user where !(wrap.contributors?.containsObject(user) ?? false) {
            wrap.mutableContributors.addObject(user)
        }
        wrap.recursivelyFetchIfNeeded(success, failure: failure)
    }
    
    override func submit() {
        guard let wrap = wrap else { return }
        if wrap.isPublic && !inserted {
            wrap.notifyOnUpdate(.ContributorsChanged)
        } else {
            wrap.notifyOnAddition()
        }
    }
}

class ContributorDeleteNotification: WrapNotification {
    
    override func submit() {
        guard let wrap = wrap else { return }
        guard let body = body else { return }
        let userData = body["user"] as? [String: AnyObject]
        if let user = userData != nil ? User.mappedEntry(userData!) : User.entry(body["user_uid"] as? String) {
            if user.current && !wrap.isPublic {
                wrap.remove()
            } else {
                wrap.mutableContributors.removeObject(user)
                wrap.notifyOnUpdate(.ContributorsChanged)
            }
        }
    }
}

class WrapUpdateNotification: WrapNotification {
    
    override func submit() {
        wrap?.notifyOnUpdate(.Default)
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        if descriptor?.data == nil {
            wrap?.fetch({ (_) -> Void in
                success()
                }, failure: failure)
        } else {
            success()
        }
    }
}

class WrapDeleteNotification: WrapNotification {
    
    internal override func shouldCreateEntry(descriptor: EntryDescriptor) -> Bool {
        return descriptor.entryExists()
    }
    
    override func submit() {
        wrap?.remove()
    }
}

class LiveBroadcastNotification: WrapNotification {
    
    var liveBroadcast: LiveBroadcast?
    
    override func createEntry(descriptor: EntryDescriptor) {
        super.createEntry(descriptor)
        if let body = body {
            guard let userUID = body["user_uid"] as? String else { return }
            guard let deviceUID = body["device_uid"] as? String else { return }
            guard let wrap = wrap else { return }
            let broadcast = LiveBroadcast()
            broadcast.broadcaster = User.entry(userUID)
            broadcast.wrap = wrap
            broadcast.title = body["title"] as? String
            broadcast.streamName = "\(wrap.uid)-\(userUID)-\(deviceUID)"
            liveBroadcast = wrap.addBroadcast(broadcast)
        }
    }
    
    override func presentWithIdentifier(identifier: String?) {
        super.presentWithIdentifier(identifier)
        guard let nc = UINavigationController.mainNavigationController() else { return }
        guard let controller = wrap?.viewControllerWithNavigationController(nc) as? WLWrapViewController else { return }
        guard let liveBroadcast = liveBroadcast else { return }
        Dispatch.mainQueue.after(0.1) { _ in
            controller.presentLiveProadcast(liveBroadcast)
        }
    }
    
    override func submit() {
        wrap?.notifyOnUpdate(.Default)
    }
}
