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
        case "presentEntry":
            presentEntry(success, failure: failure)
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
        default:
            failure(ExtensionError(message: "Unknown action."))
            break
        }
    }
    
    func authorize(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        success(ExtensionReply())
    }
    
    func presentEntry(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let entry = parameters as? [String : String] {
            EventualEntryPresenter.sharedPresenter.presentEntry(entry)
            success(ExtensionReply())
        } else {
            failure(ExtensionError(message: "No entry."))
        }
    }
    
    func postComment(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        
        if let userInfo = parameters,
            let candyReference = userInfo["candy"] as? [String : String],
            let candy = Candy.deserializeReference(candyReference),
            let text = userInfo["text"] as? String {
                candy.uploadComment(text)
            success(ExtensionReply())
        } else {
            failure(ExtensionError(message: "Photo isn't available."))
        }
    }
    
    func postMessage(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let userInfo = parameters,
            let wrapReference = userInfo["wrap"] as? [String : String],
            let wrap = Wrap.deserializeReference(wrapReference),
            let text = userInfo["text"] as? String {
                wrap.uploadMessage(text)
                success(ExtensionReply())
        } else {
            failure(ExtensionError(message: "Wrap isn't available."))
        }
    }
    
    func handleNotification(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        success(ExtensionReply())
//        guard let notification = userInfo else {
//            return
//        }
//        
//        WLNotificationCenter.defaultCenter().handleRemoteNotification(notification, success: { (notification) -> Void in
//            if let entry = (notification as? WLNotification)?.entry {
//                completionHandler?(ExtensionReply(reply:  ["entry":entry.serializeReference()]))
//            } else {
//                completionHandler?(ExtensionError(message: "No data"))
//            }
//            }) { (error) -> Void in
//                completionHandler?(ExtensionResponse.failure(error?.localizedDescription))
//        }
    }
    
    func recentUpdates(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        let updates = Contribution.recentContributions(10).map { (c) -> [String:AnyObject] in
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
        success(ExtensionReply(reply:  ["updates":updates]))
    }
    
    func getCandy(success: (ExtensionReply -> Void), failure: (ExtensionError -> Void)) {
        if let uid = parameters?["uid"] as? String, let candy = Candy.entry(uid, allowInsert: false) {
            success(ExtensionReply(reply: candy.extensionCandy(includeComments: true).toDictionary()))
        } else {
            failure(ExtensionError(message: "no candy"))
        }
    }
}

extension Candy {
    func extensionCandy(includeComments includeComments: Bool) -> ExtensionCandy {
        let candy = ExtensionCandy()
        candy.uid = identifier ?? ""
        let contributor = ExtensionUser()
        contributor.uid = self.contributor?.identifier ?? ""
        contributor.name = self.contributor?.name
        contributor.avatar = self.contributor?.picture?.small
        candy.contributor = contributor
        candy.updatedAt = updatedAt
        candy.createdAt = createdAt
        candy.asset = picture?.small
        let wrap = ExtensionWrap()
        wrap.uid = self.wrap?.identifier ?? ""
        wrap.name = self.wrap?.name
        candy.wrap = wrap
        if let comments = comments as? Set<Comment> where includeComments {
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
        comment.uid = identifier ?? ""
        let contributor = ExtensionUser()
        contributor.uid = self.contributor?.identifier ?? ""
        contributor.name = self.contributor?.name
        contributor.avatar = self.contributor?.picture?.small
        comment.contributor = contributor
        comment.updatedAt = updatedAt
        comment.createdAt = createdAt
        comment.text = text
        return comment
    }
}
