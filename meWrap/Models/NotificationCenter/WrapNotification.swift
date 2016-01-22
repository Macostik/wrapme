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
        createEntryIfNeeded()
        guard let wrap = wrap else {
            success()
            return
        }
        if let user = user where !wrap.contributors.contains(user) {
            wrap.contributors.insert(user)
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
                wrap.contributors.remove(user)
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
        createEntryIfNeeded()
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
    
    override func canBeHandled() -> Bool {
        return false
    }
    
    var liveBroadcast: LiveBroadcast?
    
    override func setup(body: [String : AnyObject]) {
        super.setup(body)
        if let streamInfo = body["stream_info"] as? [String:String] {
            createDescriptor(Wrap.self, body: streamInfo, key: Keys.UID.Wrap)
        }
    }
    
    override func createEntry(descriptor: EntryDescriptor) {
        if let body = body, let streamInfo = body["stream_info"] as? [String:String] {
            guard let userUID = streamInfo["user_uid"] else { return }
            guard let deviceUID = streamInfo["device_uid"] else { return }
            guard let wrap = Wrap.entry(descriptor.uid) else { return }
            self.wrap = wrap
            _entry = wrap
            let broadcast = LiveBroadcast()
            broadcast.broadcaster = User.entry(userUID)
            broadcast.wrap = wrap
            broadcast.title = streamInfo["title"]
            broadcast.streamName = "\(wrap.uid)-\(userUID)-\(deviceUID)"
            liveBroadcast = wrap.addBroadcast(broadcast)
        }
    }
    
    override func presentWithIdentifier(identifier: String?) {
        super.presentWithIdentifier(identifier)
        guard let nc = UINavigationController.main() else { return }
        weak var controller = wrap?.viewControllerWithNavigationController(nc) as? WLWrapViewController
        guard let liveBroadcast = liveBroadcast else { return }
        Dispatch.mainQueue.after(1.2) { _ in
            controller?.presentLiveProadcast(liveBroadcast)
        }
    }
    
    override func submit() {
        wrap?.notifyOnUpdate(.Default)
    }
}
