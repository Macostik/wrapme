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
        weak var controller = UINavigationController.main()?.topViewController as? HistoryViewController
        if controller == nil || controller?.candy?.comments.contains(comment) == false {
            if comment.contributor?.current == false && !isHistorycal {
                comment.markAsUnread(false)
                EntryToast.showCommentAddition(comment)
            }
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