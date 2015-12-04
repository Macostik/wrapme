//
//  NotificationController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class NotificationController: WKUserNotificationInterfaceController {
    
    @IBOutlet weak var image: WKInterfaceImage!
    @IBOutlet weak var alertLabel: WKInterfaceLabel!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    
    override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: (WKUserNotificationInterfaceType) -> Void) {
        alertLabel.setText(alertMessageFromNotification(remoteNotification))
        titleLabel.setText(titleMessageFromNotification(remoteNotification))
        if let notification = remoteNotification as? [String : AnyObject] {
            WCSession.defaultSession().handleNotification(notification, success: { (reply) -> Void in
                //        Entry *entry = [Entry deserializeReference:[dictionary dictionaryForKey:@"entry"]];
                //        if (entry) {
                //            self.image.URL = entry.asset.small;
                //        } else {
                //            [self.image setHidden:YES];
                //        }
                }, failure: nil)
        }
        completionHandler(.Custom)
    }
    
    private func alertMessageFromNotification(notification: [NSObject : AnyObject]) -> String {
        guard let alert = notification["aps"]?["alert"] else { return "" }
        if let alert = alert as? String {
            return alert
        } else if let alert = alert as? [String : AnyObject] {
            guard let localizedAlert = alert["loc-key"] as? String else { return "" }
            guard let args = alert["loc-args"] as? [String] else { return "" }
            if args.isEmpty {
                return localizedAlert
            } else if args.count == 1 {
                return String(format: localizedAlert.ls, args[0])
            } else if args.count == 2 {
                return String(format: localizedAlert.ls, args[0], args[1])
            } else {
                return String(format: localizedAlert.ls, args[0], args[1], args[2])
            }
        } else {
            return ""
        }
    }
    
    private func titleMessageFromNotification(notification: [NSObject : AnyObject]) -> String {
        guard let alert = notification["aps"]?["alert"] else { return "" }
        if let alert = alert as? String {
            return alert
        } else if let alert = alert as? [String : AnyObject] {
            guard let localizedAlert = alert["title-loc-key"] as? String else { return "" }
            guard let args = alert["title-loc-args"] as? [String] else { return "" }
            if args.isEmpty {
                return localizedAlert
            } else if args.count == 1 {
                return String(format: localizedAlert.ls, args[0])
            } else if args.count == 2 {
                return String(format: localizedAlert.ls, args[0], args[1])
            } else {
                return String(format: localizedAlert.ls, args[0], args[1], args[2])
            }
        } else {
            return ""
        }
    }
}