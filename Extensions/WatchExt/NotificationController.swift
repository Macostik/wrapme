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

class NotificationController: WKUserNotificationInterfaceController, WCSessionDelegate {
    
    @IBOutlet weak var image: WKInterfaceImage!
    @IBOutlet weak var alertLabel: WKInterfaceLabel!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    
    override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: (WKUserNotificationInterfaceType) -> Void) {
        let alert = alertFromNotification(remoteNotification)
        alertLabel.setText(alert.message)
        titleLabel.setText(alert.title)
        if let notification = remoteNotification as? [String : AnyObject] {
            if WCSession.isSupported() {
                let session = WCSession.defaultSession()
                session.delegate = self
                session.activateSession()
            }
            WCSession.defaultSession().handleNotification(notification, success: { [weak self] (reply) -> Void in
                if let url = reply?["url"] as? String {
                    self?.image.setURL(url)
                } else {
                    self?.image.setHidden(true)
                }
                completionHandler(.Custom)
                })
        } else {
            completionHandler(.Custom)
        }
    }
    
    private func localizedString(localizedAlert: String?, args: [String]?) -> String {
        guard let localizedAlert = localizedAlert else { return "" }
        guard let args = args else { return "" }
        if args.isEmpty {
            return localizedAlert.ls
        } else if args.count == 1 {
            return String(format: localizedAlert.ls, args[0])
        } else if args.count == 2 {
            return String(format: localizedAlert.ls, args[0], args[1])
        } else {
            return String(format: localizedAlert.ls, args[0], args[1], args[2])
        }
    }
    
    private func alertFromNotification(notification: [NSObject : AnyObject]) -> (message: String, title: String) {
        let alert = notification["aps"]?["alert"]
        if let alert = alert as? String {
            return (alert, alert)
        } else if let alert = alert as? [String : AnyObject] {
            let message = localizedString(alert["loc-key"] as? String, args: alert["loc-args"] as? [String])
            let title = localizedString(alert["title-loc-key"] as? String, args: alert["title-loc-args"] as? [String])
            return (message,title)
        } else {
            return ("","")
        }
    }
}