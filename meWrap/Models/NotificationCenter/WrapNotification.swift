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
        wrap.notifyOnAddition()
        if wrap.contributor?.current == false && user?.current == true && !isHistorycal {
            InAppNotification.showWrapInvitation(wrap, inviter: inviter)
        }
    }
}

class ContributorDeleteNotification: WrapNotification {
    
    override func submit() {
        guard let wrap = _entry else { return }
        guard let body = body else { return }
        let userData = body["user"] as? [String: AnyObject]
        if let user: User = userData != nil ? mappedEntry(userData!) : User.entry(body["user_uid"] as? String) {
            if user.current {
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
    
    override func createEntry() {
        if let info = body?["stream_info"] as? [String:String] {
            guard let userUID = info["user_uid"] else { return }
            guard let deviceUID = info["device_uid"] else { return }
            guard let wrap = Wrap.entry(info["wrap_uid"]) else { return }
            _entry = wrap
            let broadcast = LiveBroadcast()
            broadcast.broadcaster = User.entry(userUID)
            broadcast.wrap = wrap
            broadcast.title = info["title"]
            broadcast.streamName = "\(wrap.uid)-\(userUID)-\(deviceUID)"
            liveBroadcast = wrap.addBroadcast(broadcast)
        }
    }
    
    override func presentWithIdentifier(identifier: String?, completionHandler: (() -> ())?) {
        super.presentWithIdentifier(identifier, completionHandler: {
            guard let wrap = self._entry, let liveBroadcast = self.liveBroadcast else {
                completionHandler?()
                return
            }
            Dispatch.mainQueue.after(1.2) { _ in
                if let controller = wrap.createViewControllerIfNeeded() as? WrapViewController {
                    controller.presentLiveBroadcast(liveBroadcast)
                    completionHandler?()
                } else {
                    completionHandler?()
                }
            }
        })
    }
    
    override func submit() {
        _entry?.notifyOnUpdate(.Default)
    }
}
