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
    func performAction(action: String, parameters: [String : AnyObject]?, success:(([String : AnyObject]?) -> Void)?, failure:((NSError?) -> Void)?) {
        
        let request = ExtensionRequest(action: action, parameters: parameters)
        sendMessage(["request":request.toDictionary()], replyHandler: { (replyMessage) -> Void in
            if let dictionary = replyMessage["success"] as? [String : AnyObject] {
                success?(ExtensionReply.fromDictionary(dictionary).reply)
            } else if  let dictionary = replyMessage["error"] as? [String : AnyObject] {
                failure?(ExtensionError.fromDictionary(dictionary).generateError())
            } else {
                failure?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey:"invalid data"]))
            }
            }) { (error) -> Void in
                failure?(error)
        }
    }
    
    func postMessage(text: String, wrap:String, success:(([String : AnyObject]?) -> Void)?, failure:((NSError?) -> Void)?) {
        performAction("postMessage", parameters: [Keys.UID.Wrap:wrap,"text":text], success: success, failure: failure)
    }
    
    func postComment(text: String, candy:String, success:(([String : AnyObject]?) -> Void)?, failure:((NSError?) -> Void)?) {
        performAction("postComment", parameters: [Keys.UID.Candy:candy,"text":text], success: success, failure: failure)
    }
    
    func handleNotification(notification: Dictionary<String,AnyObject>, success:(([String : AnyObject]?) -> Void)?, failure:((NSError?) -> Void)?) {
        performAction("handleNotification", parameters: notification, success: success, failure: failure)
    }
    
    func recentUpdates(success:([ExtensionUpdate] -> Void)?, failure:(NSError? -> Void)?) {
        performAction("recentUpdates", parameters: nil, success: { (reply) -> Void in
            var updates = [ExtensionUpdate]()
            if let array = reply?["updates"] as? [[String:AnyObject]] {
                for dictionary in array {
                    updates.append(ExtensionUpdate.fromDictionary(dictionary))
                }
            }
            success?(updates)
            }, failure: failure)
    }
    
    func getCandy(candy: ExtensionCandy, success:(ExtensionCandy -> Void)?, failure:(NSError? -> Void)?) {
        performAction("getCandy", parameters: ["uid":candy.uid], success: { (reply) -> Void in
            if let reply = reply {
                success?(ExtensionCandy.fromDictionary(reply))
            } else {
                failure?(nil)
            }
            }, failure: failure)
    }
}