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
        WCSession.defaultSession().handleNotification(notification, success: { (reply) -> Void in
//            guard let reply = reply, let reference = reply["entry"] as? [String : String] else {
//                return
//            }
//            guard let entry = reference["name"] else {
//                return
//            }
//            if entry == "Comment" {
//                let candy =
//                rootInterfaceController.pushControllerWithName("candy", context: entry.container)
//            } else if entry == "Candy" {
//                rootInterfaceController.pushControllerWithName("candy", context: entry)
//            } else if identifier == "reply" && entry == "Message" {
//                rootInterfaceController.presentTextSuggestionsFromPlistNamed("chat_presets", completionHandler: { (text) -> Void in
//                    guard let wrap = (entry as! Message).wrap, let wrap_uid = wrap.identifier else {
//                        return
//                    }
//                    WCSession.defaultSession().postMessage(text, wrap: wrap_uid, success: { (reply) -> Void in
//                        rootInterfaceController.pushControllerWithName("alert", context: "Message \"\(text)\" sent!")
//                        }, failure: { (error) -> Void in
//                            rootInterfaceController.pushControllerWithName("alert", context: error)
//                    })
//                })
//            }
            }) { (error) -> Void in
            rootInterfaceController.pushControllerWithName("alert", context: error)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        let manager = NSFileManager.defaultManager()
        let fromURL = file.fileURL
        if let toURL = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last?.URLByAppendingPathComponent(fromURL.lastPathComponent ?? "CoreData.sqlite") {
            do {
                try manager.removeItemAtURL(toURL)
                try manager.moveItemAtURL(fromURL, toURL: toURL)
                NSNotificationCenter.defaultCenter().postNotificationName("recentUpdatesChanged", object: nil)
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
}