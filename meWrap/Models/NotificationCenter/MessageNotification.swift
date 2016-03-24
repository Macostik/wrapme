//
//  MessageNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class MessageAddNotification: EntryNotification<Message> {
    
    override func dataKey() -> String { return "chat" }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if let message = _entry {
            message.recursivelyFetchIfNeeded(success, failure: failure)
        } else {
            success()
        }
    }
    
    override func submit() {
        guard let message = _entry else { return }
        if inserted && message.contributor != User.currentUser {
            message.markAsUnread(true)
        }
        message.notifyOnAddition()
    }
    
    override func presentWithIdentifier(identifier: String?) {
        super.presentWithIdentifier(identifier)
        if let nc = UINavigationController.main() {
            let controller = _entry?.viewControllerWithNavigationController(nc) as? WrapViewController
            controller?.segment = .Chat
            if identifier == "reply" {
                controller?.showKeyboard = true
            }
        }
    }
}