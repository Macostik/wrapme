//
//  MessageNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class MessageAddNotification: Notification {
    
    var message: Message?
    
    override func playSound() -> Bool {
        guard super.playSound() else { return false }
        return message?.contributor != User.currentUser
    }
    
    override func soundType() -> Sound { return .s03 }
    
    internal override func setup(body: [String:AnyObject]) {
        super.setup(body)
        createDescriptor(Message.self, body: body, key: "chat")
        descriptor?.container = Wrap.uid(body)
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if let message = message {
            message.recursivelyFetchIfNeeded(success, failure: failure)
        } else {
            success()
        }
    }
    
    internal override func createEntry(descriptor: EntryDescriptor) {
        message = getEntry(Message.self, descriptor: descriptor, mapper: { $0.map($1) })
    }
    
    override func submit() {
        guard let message = message else { return }
        if inserted && message.contributor != User.currentUser {
            message.markAsUnread(true)
        }
        message.notifyOnAddition()
    }
    
    override func presentWithIdentifier(identifier: String?) {
        super.presentWithIdentifier(identifier)
        if let nc = UINavigationController.main() {
            let controller = message?.viewControllerWithNavigationController(nc) as? WrapViewController
            controller?.segment = .Chat
            if identifier == "reply" {
                controller?.showKeyboard = true
            }
        }
    }
}