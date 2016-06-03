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
        
        var read = false
        if let controller = UINavigationController.main.topViewController as? WrapViewController {
            if controller.segment == .Chat && controller.wrap == message.wrap {
                read = true
            }
        }
        
        if inserted && message.contributor != User.currentUser && !read {
            message.markAsUnread(true)
        }
        message.notifyOnAddition()
        
        if message.contributor?.current == false && !isHistorycal && !read {
            InAppNotification.showMessageAddition(message)
        }
    }
    
    override func presentWithIdentifier(identifier: String?, completionHandler: (() -> ())?) {
        super.presentWithIdentifier(identifier, completionHandler: completionHandler)
        if let controller = _entry?.createViewControllerIfNeeded() as? WrapViewController {
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