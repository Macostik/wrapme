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
        var allow = true
        let topViewController = UINavigationController.main.topViewController as? WrapViewController
        if topViewController?.segment == .Chat {
            let wrap = topViewController?.wrap
            if wrap == message.wrap {
                allow = false
            }
        }
        if message.contributor?.current == false && !isHistorycal && allow {
            EntryToast.showMessageAddition(message)
        }
    }
    
    override func presentWithIdentifier(identifier: String?) {
        super.presentWithIdentifier(identifier)
        let nc = UINavigationController.main
        if let controller = _entry?.viewControllerWithNavigationController(nc) as? WrapViewController {
            controller.segment = .Chat
            if identifier == "reply" {
                performWhenLoaded(controller.chatViewController, block: { controller in
                    Dispatch.mainQueue.async({
                        controller.composeBar.becomeFirstResponder()
                    })
                })
            }
        }
    }
}