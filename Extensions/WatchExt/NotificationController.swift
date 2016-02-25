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
            WCSession.defaultSession().handleNotification(notification, success: { [weak self] (reply) -> Void in
                        if let url = reply?["url"] as? String {
                            self?.image.setURL(url)
                        } else {
                            self?.image.setHidden(true)
                        }
                }, failure: nil)
        }
        completionHandler(.Custom)
    }
    
    private func alertMessageFromNotification(notification: [NSObject : AnyObject]) -> String {
        let alert = notification["aps"]?["alert"]
        if let alert = alert as? String {
            return alert
        } else if let alert = alert as? [String : AnyObject] {
            guard let localizedAlert = alert["loc-key"] as? String else { return "" }
            guard let args = alert["loc-args"] as? [String] else { return "" }
            if args.isEmpty {
                return localizedAlert.ls
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
        let alert = notification["aps"]?["alert"]
        if let alert = alert as? String {
            return alert
        } else if let alert = alert as? [String : AnyObject] {
            guard let localizedAlert = alert["title-loc-key"] as? String else { return "" }
            guard let args = alert["title-loc-args"] as? [String] else { return "" }
            if args.isEmpty {
                return localizedAlert.ls
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