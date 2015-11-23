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
        case "dataSync":
            dataSync(completionHandler)
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
//        if let userInfo = userInfo,
//            let candyReference = userInfo["candy"] as? [String : String],
//            let candy = Candy.deserializeReference(candyReference),
//            let text = userInfo["text"] {
//            [candy uploadComment:text success:^(Comment *comment) {
//                completionHandler?(ExtensionResponse.success(nil))
//                } failure:^(NSError *error) {
//                completionHandler?(ExtensionResponse.failure(error.localizedDescription])
//                }]
//        } else {
//            completionHandler?(ExtensionResponse.failure("Photo isn't available."))
//        }
    }
    
    func postMessage(completionHandler: (ExtensionResponse -> Void)?) {
//        if let userInfo = userInfo,
//            let wrapReference = userInfo["wrap"] as? [String : String],
//            let wrap = Wrap.deserializeReference(wrapReference),
//            let text = userInfo["text"] {
//                [wrap uploadMessage:text success:^(Message *message) {
//                    completionHandler?(ExtensionResponse.success(nil))
//                    } failure:^(NSError *error) {
//                    completionHandler?(ExtensionResponse.failure(error.localizedDescription])
//                    }]
//        } else {
//            completionHandler?(ExtensionResponse.failure("Wrap isn't available."))
//        }
    }
    
    func handleNotification(completionHandler: (ExtensionResponse -> Void)?) {
        guard let notification = userInfo else {
            return
        }
        WLNotificationCenter.defaultCenter().handleRemoteNotification(notification, success: { (notification) -> Void in
//            if let entry = (notification as? WLNotification)?.entry {
//                completionHandler?(ExtensionResponse.success(nil, userInfo: ["entry":entry.serializeReference()]))
//            } else {
//                completionHandler?(ExtensionResponse.failure("No data"))
//            }
            }) { (error) -> Void in
                completionHandler?(ExtensionResponse.failure(error?.localizedDescription))
        }
    }
    
    func dataSync(completionHandler: (ExtensionResponse -> Void)?) {
        if #available(iOS 9.0, *) {
            if WCSession.defaultSession().paired && WCSession.defaultSession().watchAppInstalled {
                // TODO:
            }
        } else {
            // Fallback on earlier versions
        }
        completionHandler?(ExtensionResponse.success(nil))
    }
}