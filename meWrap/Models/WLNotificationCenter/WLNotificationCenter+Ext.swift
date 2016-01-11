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
            guard let n = Notification.notificationWithMessage(message) else { break }
            guard n.type == .UserUpdate || Authorization.active else { break }
            guard n.type == .CandyAdd || n.type == .CandyUpdate || !n.originatedByCurrentUser else { break }
            guard !canSkipNotification(n) else { break }
            notifications.append(n)
        }
        
        if notifications.isEmpty { return nil }
        
        addHandledNotifications(notifications)
        
        return notifications.sort({ $0.publishedAt < $1.publishedAt })
    }
}