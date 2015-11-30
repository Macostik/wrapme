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
    
    func perform(completionHandler: (ExtensionResponse -> Void)?) {
        guard let action = action else {
            completionHandler?(ExtensionResponse.failure("No action."))
            return
        }
        switch action {
        case "authorize":
            authorize(completionHandler)
            break
        case "presentEntry":
            presentEntry(completionHandler)
            break
        case "postComment":
            postComment(completionHandler)
            break
        case "postMessage":
            postMessage(completionHandler)
            break
        case "handleNotification":
            handleNotification(completionHandler)
            break
        case "recentUpdates":
            recentUpdates(completionHandler)
            break
        default:
            completionHandler?(ExtensionResponse.failure("Unknown action."))
            break
        }
    }
    
    func authorize(completionHandler: (ExtensionResponse -> Void)?) {
        completionHandler?(ExtensionResponse.success(nil))
    }
    
    func presentEntry(completionHandler: (ExtensionResponse -> Void)?) {
        if let entry = self.userInfo as? [String : String] {
            EventualEntryPresenter.sharedPresenter.presentEntry(entry)
            completionHandler?(ExtensionResponse.success(nil))
        } else {
            completionHandler?(ExtensionResponse.failure("No entry."))
        }
    }
    
    func postComment(completionHandler: (ExtensionResponse -> Void)?) {
        
        if let userInfo = userInfo,
            let candyReference = userInfo["candy"] as? [String : String],
            let candy = Candy.deserializeReference(candyReference),
            let text = userInfo["text"] as? String {
                candy.uploadComment(text)
            completionHandler?(ExtensionResponse.success(nil))
        } else {
            completionHandler?(ExtensionResponse.failure("Photo isn't available."))
        }
    }
    
    func postMessage(completionHandler: (ExtensionResponse -> Void)?) {
        if let userInfo = userInfo,
            let wrapReference = userInfo["wrap"] as? [String : String],
            let wrap = Wrap.deserializeReference(wrapReference),
            let text = userInfo["text"] as? String {
                wrap.uploadMessage(text)
                completionHandler?(ExtensionResponse.success(nil))
        } else {
            completionHandler?(ExtensionResponse.failure("Wrap isn't available."))
        }
    }
    
    func handleNotification(completionHandler: (ExtensionResponse -> Void)?) {
        completionHandler?(ExtensionResponse.success(nil))
//        guard let notification = userInfo else {
//            return
//        }
//        
//        WLNotificationCenter.defaultCenter().handleRemoteNotification(notification, success: { (notification) -> Void in
//            if let entry = (notification as? WLNotification)?.entry {
//                completionHandler?(ExtensionResponse.success(nil, userInfo: ["entry":entry.serializeReference()]))
//            } else {
//                completionHandler?(ExtensionResponse.failure("No data"))
//            }
//            }) { (error) -> Void in
//                completionHandler?(ExtensionResponse.failure(error?.localizedDescription))
//        }
    }
    
    func recentUpdates(completionHandler: (ExtensionResponse -> Void)?) {
        let updates = Contribution.recentContributions().map { (c) -> [String:AnyObject] in
            let update = ExtensionUpdate()
            var candy: Candy?
            if let comment = c as? Comment {
                update.type = "comment"
                candy = comment.candy
            } else if let _candy = c as? Candy {
                update.type = "candy"
                candy = _candy
            }
            update.candy = candy?.extensionCandy(includeComments: false)
            return update.toDictionary()
        }
        completionHandler?(ExtensionResponse.success(nil, userInfo: ["updates":updates]))
    }
    
    func getCandy(completionHandler: (ExtensionResponse -> Void)?) {
        completionHandler?(ExtensionResponse.success(nil))
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
