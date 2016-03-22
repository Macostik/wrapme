//
//  CommentNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class CommentNotification: Notification {
    
    var comment: Comment?
    
    internal override func setup(body: [String:AnyObject]) {
        super.setup(body)
        createDescriptor(Comment.self, body: body, key: "comment")
        descriptor?.container = Candy.uid(body)
    }
    
    internal override func createEntry(descriptor: EntryDescriptor) {
        comment = getEntry(Comment.self, descriptor: descriptor, mapper: { $0.map($1) })
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if let comment = comment {
            comment.recursivelyFetchIfNeeded(success, failure: failure)
        } else {
            success()
        }
    }
}

class CommentAddNotification: CommentNotification {
    
    override func submit() {
        guard let comment = comment else { return }
        guard let candy = comment.candy else { return }
        if candy.valid {
            candy.commentCount = Int16(candy.comments.count)
        }
        if inserted && comment.contributor != User.currentUser {
            comment.markAsUnread(true)
        }
        comment.notifyOnAddition()
    }
}

class CommentDeleteNotification: CommentNotification {
    
    internal override func shouldCreateEntry(descriptor: EntryDescriptor) -> Bool {
        return descriptor.entryExists()
    }
    
    override func submit() {
        guard let comment = comment else { return }
        if let candy = comment.candy {
            candy.commentCount -= 1
        }
        comment.remove()
    }
}