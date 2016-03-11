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
        case "authorize":
            authorize(success, failure: failure)
            break
        case "presentCandy":
            presentCandy(success, failure: failure)
            break
        case "presentComment":
            presentComment(success, failure: failure)
            break
        case "postComment":
            postComment(success, failure: failure)
            break
        case "postMessage":
            postMessage(success, failure: failure)
            break
        case "handleNotification":
            handleNotification(success, failure: failure)
            break
        case "recentUpdates":
            recentUpdates(success, failure: failure)
            break
        case "getCandy":
            getCandy(success, failure: failure)
            break
        case "presentShareContent":
            presentShareContent(success, failure: failure)
            break
        default:
            failure(ExtensionError(message: "Unknown action."))
            break
        }
    }
    
    func authorize(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        success(ExtensionReply())
    }
    
    func presentCandy(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let uid = parameters?["uid"] as? String, let candy = Candy.entry(uid, allowInsert: false) {
            EventualEntryPresenter.sharedPresenter.presentEntry(candy.serializeReference())
            success(ExtensionReply())
        } else {
            failure(ExtensionError(message: "No entry."))
        }
    }
    
    func presentComment(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let uid = parameters?["uid"] as? String, let comment = Comment.entry(uid, allowInsert: false) {
            EventualEntryPresenter.sharedPresenter.presentEntry(comment.serializeReference())
            success(ExtensionReply())
        } else {
            failure(ExtensionError(message: "No entry."))
        }
    }
    
    func postComment(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        guard let parameters = parameters else { failure(ExtensionError(message: "Invalid data")); return }
        guard let uid = parameters[Keys.UID.Candy] as? String else { failure(ExtensionError(message: "No candy uid")); return }
        guard let candy = Candy.entry(uid, allowInsert: false) else { failure(ExtensionError(message: "Photo isn't available.")); return }
        guard let text = parameters["text"] as? String else { failure(ExtensionError(message: "No text provided.")); return }
        candy.uploadComment(text)
        success(ExtensionReply())
    }
    
    func postMessage(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        guard let parameters = parameters else { failure(ExtensionError(message: "Invalid data")); return }
        guard let uid = parameters[Keys.UID.Wrap] as? String else { failure(ExtensionError(message: "No wrap uid")); return }
        guard let wrap = Wrap.entry(uid, allowInsert: false) else { failure(ExtensionError(message: "Wrap isn't available.")); return }
        guard let text = parameters["text"] as? String else { failure(ExtensionError(message: "No text provided.")); return }
        wrap.uploadMessage(text)
        success(ExtensionReply())
    }
    
    func handleNotification(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        success(ExtensionReply())
        guard let notification = parameters else {
            return
        }
        
        NotificationCenter.handleRemoteNotification(notification, success: { (notification) -> Void in
            if let url = (notification.entry as? Contribution)?.asset?.small {
                success(ExtensionReply(reply: ["url":url]))
            } else {
                failure(ExtensionError(message: "No data"))
            }
            }) { (error) -> Void in
                failure(ExtensionError(message: error?.localizedDescription ?? ""))
        }
    }
    
    func recentUpdates(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        success(ExtensionReply(reply: ["updates":Contribution.recentUpdates(10)]))
    }
    
    func getCandy(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let uid = parameters?["uid"] as? String, let candy = Candy.entry(uid, allowInsert: false) {
            success(ExtensionReply(reply: candy.extensionCandy(includeComments: true).toDictionary()))
        } else {
            failure(ExtensionError(message: "no candy"))
        }
    }
    
    func presentShareContent(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let shareExtension = parameters as? [String : String] {
            EventualEntryPresenter.sharedPresenter.presentExtension(shareExtension)
            success(ExtensionReply())
        } else {
            failure(ExtensionError(message: "No entry."))
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
