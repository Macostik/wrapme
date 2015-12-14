//
//  WatchExtensionDelegate.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/27/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class WatchExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    func handleActionWithIdentifier(identifier: String?, forRemoteNotification remoteNotification: [NSObject : AnyObject]) {
        
        guard let notification = remoteNotification as? [String : AnyObject] else {
            return
        }
        guard let rootInterfaceController = WKExtension.sharedExtension().rootInterfaceController else {
            return
        }
        if let uid = notification["wrap_uid"] as? String where identifier == "reply" {
            rootInterfaceController.presentTextSuggestionsFromPlistNamed("chat_presets", completionHandler: { (text) -> Void in
                WCSession.defaultSession().postMessage(text, wrap: uid, success: { (reply) -> Void in
                    rootInterfaceController.pushControllerWithName("alert", context: "Message \"\(text)\" sent!")
                    }, failure: { (error) -> Void in
                        rootInterfaceController.pushControllerWithName("alert", context: error)
                })
            })
        } else if let uid = notification["candy_uid"] as? String {
            let candy = ExtensionCandy()
            candy.uid = uid
            rootInterfaceController.pushControllerWithName("candy", context: candy)
        }
    }
}