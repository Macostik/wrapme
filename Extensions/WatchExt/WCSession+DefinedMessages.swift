//
//  WCSession+Defined.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import WatchConnectivity

extension WCSession {
    func performAction(action: String, parameters: Dictionary<String,AnyObject>?, success:((Dictionary<String,AnyObject>?) -> Void)?, failure:((NSError?) -> Void)?) {
        
        let request = ExtensionRequest(action: action, userInfo: parameters)
        sendMessage(["request":request.toDictionary()], replyHandler: { (replyMessage) -> Void in
            guard let dictionary = replyMessage["response"] as? [String : AnyObject] else {
                return
            }
            let response = ExtensionResponse.fromDictionary(dictionary)
            if response.success {
                success?(response.userInfo)
            } else {
                failure?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey:response.message ?? ""]))
            }
            }) { (error) -> Void in
                failure?(error)
        }
    }
    
    func postMessage(text: String, wrap:String, success:((Dictionary<String,AnyObject>?) -> Void)?, failure:((NSError?) -> Void)?) {
        performAction("postMessage", parameters: [WLWrapUIDKey:wrap,"text":text], success: success, failure: failure)
    }
    
    func postComment(text: String, candy:String, success:((Dictionary<String,AnyObject>?) -> Void)?, failure:((NSError?) -> Void)?) {
        performAction("postComment", parameters: [WLCandyUIDKey:candy,"text":text], success: success, failure: failure)
    }
    
    func handleNotification(notification: Dictionary<String,AnyObject>, success:((Dictionary<String,AnyObject>?) -> Void)?, failure:((NSError?) -> Void)?) {
        performAction("handleNotification", parameters: notification, success: success, failure: failure)
    }
    
    func recentUpdates(success:([String : AnyObject]? -> Void)?, failure:(NSError? -> Void)?) {
        performAction("recentUpdates", parameters: nil, success: success, failure: failure)
    }
}