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
    func performAction(action: Selector, parameters: Dictionary<String,AnyObject>?, success:((Dictionary<String,AnyObject>?) -> Void)?, failure:((NSError?) -> Void)?) {
        
        let request = ExtensionRequest(action: NSStringFromSelector(action), userInfo: parameters)
        guard let dictionary = request.serialize() else {
            failure?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey:"cannot serialize message"]))
            return
        }
        sendMessage(dictionary, replyHandler: { (replyMessage) -> Void in
            guard let dictionary = replyMessage as? Dictionary<String, NSData> else {
                return
            }
            guard let response = ExtensionResponse.deserialize(dictionary) as? ExtensionResponse else {
                return
            }
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
        performAction("postMessage:completionHandler:", parameters: [WLWrapUIDKey:wrap,"text":text], success: success, failure: failure)
    }
    
    func postComment(text: String, candy:String, success:((Dictionary<String,AnyObject>?) -> Void)?, failure:((NSError?) -> Void)?) {
        performAction("postComment:completionHandler:", parameters: [WLCandyUIDKey:candy,"text":text], success: success, failure: failure)
    }
    
    func handleNotification(notification: Dictionary<String,AnyObject>, success:((Dictionary<String,AnyObject>?) -> Void)?, failure:((NSError?) -> Void)?) {
        performAction("handleNotification:completionHandler:", parameters: notification, success: success, failure: failure)
    }
    
    func dataSync(success:([String : AnyObject]? -> Void)?, failure:(NSError? -> Void)?) {
        performAction("dataSync:completionHandler:", parameters: nil, success: success, failure: failure)
    }
}