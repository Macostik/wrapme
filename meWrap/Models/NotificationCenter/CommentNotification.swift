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
        if comment.contributor != User.currentUser {
            let controller = CommentsViewController.current
            if controller == nil || controller?.candy?.comments.contains(comment) == false || controller?.isMaxContentOffset == false {
                if comment.contributor?.current == false && !isHistorycal {
                    InAppNotification.showCommentAddition(comment)
                }
            } else {
                if self.isHistorycal == false {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
            }
        }
    }
    
    override func canBeHandled() -> Bool { return Authorization.active }
}

class CommentDeleteNotification: CommentNotification {
    
    override func submit() {
        guard let comment = _entry else { return }
        comment.remove()
    }
}