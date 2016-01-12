//
//  WLNotificationCenter+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

extension WLNotificationCenter {
    
    func addHandledNotifications(notifications: [Notification]) {
        
        var handledNotifications = NSUserDefaults.standardUserDefaults().handledNotifications
        if handledNotifications.count > 100 {
            handledNotifications.removeFirst(min(100, notifications.count))
        }
        for notification in notifications {
            if let uid = notification.uid {
                handledNotifications.append(uid)
            }
        }
        
        NSUserDefaults.standardUserDefaults().handledNotifications = handledNotifications
    }
    
    func canSkipNotification(notification: Notification) -> Bool {
        if let uid = notification.uid {
            return NSUserDefaults.standardUserDefaults().handledNotifications.contains(uid) ?? false
        } else {
            return true
        }
    }
    
    func notificationsFromMessages(messages: [AnyObject]?) -> [Notification]? {
        guard let messages = messages where !messages.isEmpty else { return nil }
        
        var notifications = [Notification]()
        
        for message in messages {
            guard let n = Notification.notificationWithMessage(message) else {
                print("no notification object \(message)")
                break
            }
            guard n.canBeHandled() && !canSkipNotification(n) else {
                print("cannot be handled \(message)")
                break
            }
            notifications.append(n)
            print("added message \(message)")
        }
        
        if notifications.isEmpty { return nil }
        
        addHandledNotifications(notifications)
        
        return notifications.sort({ $0.publishedAt < $1.publishedAt })
    }
}