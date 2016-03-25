//
//  CommentNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class CommentNotification: EntryNotification<Comment> {
    
    override func dataKey() -> String { return "comment" }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if let comment = _entry {
            comment.recursivelyFetchIfNeeded(success, failure: failure)
        } else {
            success()
        }
    }
}

class CommentAddNotification: CommentNotification {
    
    override func submit() {
        guard let comment = _entry else { return }
        guard let candy = comment.candy else { return }
        if candy.valid {
            candy.commentCount = Int16(candy.comments.count)
        }
        if inserted && comment.contributor != User.currentUser {
            comment.markAsUnread(true)
        }
        comment.notifyOnAddition()
        if comment.contributor?.current == false && !isHistorycal {
             EntryToast(entry: comment).show()
        }
    }
}

class CommentDeleteNotification: CommentNotification {
    
    override func submit() {
        guard let comment = _entry else { return }
        if let candy = comment.candy {
            candy.commentCount -= 1
        }
        comment.remove()
    }
}