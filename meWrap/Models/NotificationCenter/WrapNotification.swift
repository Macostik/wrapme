//
//  WrapNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class WrapNotification: EntryNotification<Wrap> {
    
    override func dataKey() -> String { return "wrap" }
}

class ContributorAddNotification: WrapNotification {
    
    var user: User?
    
    var inviter: User?
    
    internal override func createEntry() {
        super.createEntry()
        guard let body = body else { return }
        let userData = body["user"] as? [String: AnyObject]
        user = userData != nil ? mappedEntry(userData!) : User.entry(body["user_uid"] as? String)
        if let inviter = body["inviter"] as? [String: AnyObject] {
            self.inviter = mappedEntry(inviter)
        }
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        guard let wrap = _entry else {
            success()
            return
        }
        if let user = user where !wrap.contributors.contains(user) {
            wrap.contributors.insert(user)
        }
        wrap.recursivelyFetchIfNeeded(success, failure: failure)
    }
    
    override func submit() {
        guard let wrap = _entry else { return }
        if wrap.isPublic && !inserted {
            wrap.notifyOnUpdate(.ContributorsChanged)
        } else {
            wrap.notifyOnAddition()
            if wrap.contributor?.current == false && user?.current == true && !isHistorycal {
                EntryToast.showWrapInvitation(wrap, inviter: inviter)
            }
        }
    }
}

class ContributorDeleteNotification: WrapNotification {
    
    override func submit() {
        guard let wrap = _entry else { return }
        guard let body = body else { return }
        let userData = body["user"] as? [String: AnyObject]
        if let user: User = userData != nil ? mappedEntry(userData!) : User.entry(body["user_uid"] as? String) {
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
        _entry?.notifyOnUpdate(.Default)
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if entryData == nil {
            _entry?.fetch({ (_) -> Void in
                success()
                }, failure: failure)
        } else {
            success()
        }
    }
}

class WrapDeleteNotification: WrapNotification {
    
    override func submit() {
        _entry?.remove()
    }
}

class LiveBroadcastNotification: WrapNotification {
    
    override func canBeHandled() -> Bool {
        return false
    }
    
    var liveBroadcast: LiveBroadcast?
    
    override func setupEntryData(body: [String : AnyObject]) {
        if let streamInfo = body["stream_info"] as? [String:String] {
            super.setupEntryData(streamInfo)
        }
    }
    
    override func createEntry() {
        if let body = body, let streamInfo = body["stream_info"] as? [String:String] {
            guard let userUID = streamInfo["user_uid"] else { return }
            guard let deviceUID = streamInfo["device_uid"] else { return }
            guard let wrap = Wrap.entry(entryUid) else { return }
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
        weak var controller = _entry?.viewControllerWithNavigationController(nc) as? WrapViewController
        guard let liveBroadcast = liveBroadcast else { return }
        Dispatch.mainQueue.after(1.2) { _ in
            controller?.presentLiveBroadcast(liveBroadcast)
        }
    }
    
    override func submit() {
        _entry?.notifyOnUpdate(.Default)
    }
}
