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
        
        guard let rootInterfaceController = WKExtension.sharedExtension().rootInterfaceController else { return }
        if let uid = remoteNotification["chat"]?["wrap_uid"] as? String where identifier == "reply" {
            rootInterfaceController.presentTextSuggestionsFromPlistNamed("chat_presets", completionHandler: { text in
                WCSession.defaultSession().postMessage(text, wrap: uid, success: { _ in
                    rootInterfaceController.pushControllerWithName("alert", context: "Message \"\(text)\" sent!")
                    }, failure: { rootInterfaceController.pushControllerWithName("alert", context: $0) })
            })
        } else if let uid = remoteNotification["candy_uid"] as? String ?? remoteNotification["candy"]?["candy_uid"] as? String {
            let candy = ExtensionCandy()
            candy.uid = uid
            rootInterfaceController.pushControllerWithName("candy", context: candy)
        }
    }
}