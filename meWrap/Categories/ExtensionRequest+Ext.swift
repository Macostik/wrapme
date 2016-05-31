//
//  ExtensionRequest+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import WatchConnectivity

extension ExtensionRequest {
    
    func perform(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        guard let action = action else {
            failure(ExtensionError(message: "No action."))
            return
        }
        switch action {
        case .Authorize: authorize(success, failure: failure)
        case .PresentCandy: presentCandy(success, failure: failure)
        case .PresentComment: presentComment(success, failure: failure)
        case .PostComment: postComment(success, failure: failure)
        case .PostMessage: postMessage(success, failure: failure)
        case .HandleNotification: handleNotification(success, failure: failure)
        case .RecentUpdates: recentUpdates(success, failure: failure)
        case .GetCandy: getCandy(success, failure: failure)
        case .PresentShareContent: presentShareContent(success, failure: failure)
        }
    }
    
    private func authorize(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        success(ExtensionReply())
    }
    
    private func presentCandy(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let uid = parameters?["uid"] as? String, let candy = Candy.entry(uid, allowInsert: false) {
            AuthorizedExecutor.presentEntry(candy)
            success(ExtensionReply())
        } else {
            failure(ExtensionError(message: "No entry."))
        }
    }
    
    private func presentComment(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let uid = parameters?["uid"] as? String, let comment = Comment.entry(uid, allowInsert: false) {
            AuthorizedExecutor.presentEntry(comment)
            success(ExtensionReply())
        } else {
            failure(ExtensionError(message: "No entry."))
        }
    }
    
    private func postComment(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        guard let parameters = parameters else { failure(ExtensionError(message: "Invalid data")); return }
        guard let uid = parameters[Keys.UID.Candy] as? String else { failure(ExtensionError(message: "No candy uid")); return }
        guard let candy = Candy.entry(uid, allowInsert: false) else { failure(ExtensionError(message: "Photo isn't available.")); return }
        guard let text = parameters["text"] as? String else { failure(ExtensionError(message: "No text provided.")); return }
        candy.uploadComment(Comment.comment(text))
        success(ExtensionReply())
    }
    
    private func postMessage(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        guard let parameters = parameters else { failure(ExtensionError(message: "Invalid data")); return }
        guard let uid = parameters[Keys.UID.Wrap] as? String else { failure(ExtensionError(message: "No wrap uid")); return }
        guard let wrap = Wrap.entry(uid, allowInsert: false) else { failure(ExtensionError(message: "Wrap isn't available.")); return }
        guard let text = parameters["text"] as? String else { failure(ExtensionError(message: "No text provided.")); return }
        wrap.uploadMessage(text)
        success(ExtensionReply())
    }
    
    private func handleNotification(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        guard let notification = parameters else {
            failure(ExtensionError(message: "No data"))
            return
        }
        NotificationCenter.handleRemoteNotification(notification, success: { (notification) -> Void in
            if let url = (notification.getEntry() as? Contribution)?.asset?.small {
                success(ExtensionReply(reply: ["url":url]))
            } else {
                failure(ExtensionError(message: "No data"))
            }
            }) { failure(ExtensionError(message: $0?.localizedDescription ?? "")) }
    }
    
    private func recentUpdates(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        success(ExtensionReply(reply: ["updates":Contribution.recentUpdates(10)]))
    }
    
    private func getCandy(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let uid = parameters?["uid"] as? String, let candy = Candy.entry(uid, allowInsert: false) {
            success(ExtensionReply(reply: candy.extensionCandy(includeComments: true).toDictionary()))
        } else {
            failure(ExtensionError(message: "no candy"))
        }
    }
    
    private func presentShareContent(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let items = parameters?["items"] as? [[String:String]] {
            AuthorizedExecutor.shareContent(items)
            success(ExtensionReply())
        }
    }
}

extension Contribution {
    class func recentUpdates(limit: Int) -> [[String:AnyObject]] {
        return Contribution.recentContributions(limit).map { (c) -> [String:AnyObject] in
            let update = ExtensionUpdate()
            if let comment = c as? Comment {
                update.comment = comment.extensionComment()
                update.type = "comment"
                update.candy = comment.candy?.extensionCandy(includeComments: false)
            } else if let candy = c as? Candy {
                update.type = "candy"
                update.candy = candy.extensionCandy(includeComments: false)
            }
            return update.toDictionary()
        }
    }
}

extension Wrap {
    func extensionWrap() -> ExtensionWrap {
        let wrap = ExtensionWrap()
        wrap.uid = uid ?? ""
        wrap.name = self.name
        wrap.lastCandy = self.asset?.small
        wrap.updatedAt = self.updatedAt.timeAgoStringAtAMPM()
        return wrap
    }
}

extension Candy {
    func extensionCandy(includeComments includeComments: Bool) -> ExtensionCandy {
        let candy = ExtensionCandy()
        candy.uid = uid ?? ""
        let contributor = ExtensionUser()
        contributor.uid = self.contributor?.uid ?? ""
        contributor.name = self.contributor?.name
        contributor.avatar = self.contributor?.avatar?.small
        candy.contributor = contributor
        candy.updatedAt = updatedAt
        candy.createdAt = createdAt
        candy.asset = asset?.small
        let wrap = ExtensionWrap()
        wrap.uid = self.wrap?.uid ?? ""
        wrap.name = self.wrap?.name
        candy.wrap = wrap
        if includeComments {
            candy.comments = Array(comments).map({ (comment) -> ExtensionComment in
                return comment.extensionComment()
            })
        }
        candy.type = mediaType
        return candy
    }
}

extension Comment {
    func extensionComment() -> ExtensionComment {
        let comment = ExtensionComment()
        comment.uid = uid ?? ""
        let contributor = ExtensionUser()
        contributor.uid = self.contributor?.uid ?? ""
        contributor.name = self.contributor?.name
        contributor.avatar = self.contributor?.avatar?.small
        comment.contributor = contributor
        comment.updatedAt = updatedAt
        comment.createdAt = createdAt
        comment.text = text
        return comment
    }
}
