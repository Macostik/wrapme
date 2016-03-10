//
//  Notification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

enum NotificationType: Int {
    
    case ContributorAdd        = 100
    case ContributorDelete     = 200
    case CandyAdd              = 300
    case CandyDelete           = 400
    case CommentAdd            = 500
    case CommentDelete         = 600
    case MessageAdd            = 700
    case WrapDelete            = 800
    case UserUpdate            = 900
    case WrapUpdate            = 1000
    case UpdateAvailable       = 1100
    case CandyUpdate           = 1200
    case LiveBroadcast         = 1300
    
    func typeValue() -> Notification.Type {
        switch self {
        case .ContributorAdd: return ContributorAddNotification.self
        case .ContributorDelete: return ContributorDeleteNotification.self
        case .WrapDelete: return WrapDeleteNotification.self
        case .WrapUpdate: return WrapUpdateNotification.self
        case .CandyAdd: return CandyAddNotification.self
        case .CandyDelete: return CandyDeleteNotification.self
        case .CandyUpdate: return CandyUpdateNotification.self
        case .MessageAdd: return MessageAddNotification.self
        case .CommentAdd: return CommentAddNotification.self
        case .CommentDelete: return CommentDeleteNotification.self
        case .UserUpdate: return UserUpdateNotification.self
        case .UpdateAvailable: return UpdateAvailableNotification.self
        case .LiveBroadcast: return LiveBroadcastNotification.self
        }
    }
}

class UpdateAvailableNotification: Notification {
    override func presentWithIdentifier(identifier: String?) {
        if let url = "itms-apps://itunes.apple.com/app/id\(Constants.appStoreID)".URL {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}

class Notification: NSObject {
    var uid: String?
    
    func playSound() -> Bool {
        if let alert = body?["pn_apns"]?["aps"]?["alert"] {
            return entry != nil && alert != nil
        } else {
            return false
        }
    }
    
    func soundType() -> Sound? { return nil }
        
    var publishedAt: NSDate
    var body: [String:AnyObject]?
    var descriptor: EntryDescriptor?
    var inserted = false
    var originatedByCurrentUser = false
    var type: NotificationType
    
    private class func parseMessage(message: AnyObject?) -> (body: [String:AnyObject]?, timetoken: NSNumber?) {
        if let message = message as? PNMessageData {
            return (message.message as? [String:AnyObject], message.timetoken)
        } else if let message = message as? [String:AnyObject] {
            return (message["message"] as? [String:AnyObject], message["timetoken"] as? NSNumber)
        } else {
            return (nil, nil)
        }
    }
    
    private class func parseNotificationType(data: [String:AnyObject]) -> NotificationType? {
        guard let type = data["msg_type"] as? Int else { return nil }
        return NotificationType(rawValue: type)
    }
    
    class func notificationWithMessage(message: AnyObject?) -> Notification? {
        let result = parseMessage(message)
        guard let body = result.body, let timetoken = result.timetoken else {
            return nil
        }
        let publishedAt = NSDate(timetoken:timetoken)
        return notificationWithBody(body, publishedAt: publishedAt)
    }
    
    class func notificationWithBody(body: [String:AnyObject], publishedAt: NSDate?) -> Notification? {
        guard let type = parseNotificationType(body) else {
            return nil
        }
        return type.typeValue().init(type: type, body: body, publishedAt: publishedAt)
    }
    
    required init(type: NotificationType, body: [String:AnyObject], publishedAt: NSDate?) {
        self.publishedAt = publishedAt ?? NSDate(timeIntervalSince1970: 0)
        self.body = body
        self.uid = body["msg_uid"] as? String
        self.type = type
        super.init()
        setup(body)
    }
    
    internal func setup(body: [String:AnyObject]) {
        if let originator = body["originator"] as? [String:AnyObject] {
            let userID = originator["user_uid"] as? String
            let deviceID = originator["device_uid"] as? String
            originatedByCurrentUser = userID == User.currentUser?.uid && deviceID == Authorization.current.deviceUID
        }
    }
    
    internal func createDescriptor<T: Entry>(type: T.Type, body: [String:AnyObject], key: String) {
        let entryData = body[key] as? [String:AnyObject]
        if let uid = T.uid(entryData ?? body) {
            var descriptor = EntryDescriptor(name: T.entityName(), uid: uid, locuid: T.locuid(entryData ?? body))
            descriptor.data = entryData
            self.descriptor = descriptor
        }
    }
    
    internal func getEntry<T: Entry>(type: T.Type, descriptor: EntryDescriptor, @noescape mapper: ((entry: T, data: [String:AnyObject]) -> Void)) -> T? {
        guard let entry = T.entry(descriptor.uid, locuid:descriptor.locuid) else { return nil }
        
        if let data = descriptor.data {
            mapper(entry: entry, data: data)
        }
        
        if let containerType = T.containerType() where entry.container == nil {
            entry.container = containerType.entry(descriptor.container, locuid: nil, allowInsert: false)
        }
        _entry = entry
        return entry
    }
    
    internal var _entry: Entry?
    var entry: Entry? {
        createEntryIfNeeded()
        return _entry
    }
    
    internal func shouldCreateEntry(descriptor: EntryDescriptor) -> Bool { return true }
    
    internal func createEntryIfNeeded() {
        if _entry == nil {
            if let descriptor = descriptor where shouldCreateEntry(descriptor) {
                createEntry(descriptor)
            }
            inserted = _entry?.inserted ?? false
        }
    }
    
    internal func createEntry(descriptor: EntryDescriptor) { }

    func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        success()
    }
    
    func submit() { }
    
    func handle(success: Block, failure: FailureBlock) {
        fetch({ _ in
            self.submit()
            success()
            }, failure: failure)
    }
    
    override var description: String {
        return "\(type.rawValue): \(descriptor?.description ?? "")"
    }
    
    func canBeHandled() -> Bool { return Authorization.active && !originatedByCurrentUser }
    
    func presentWithIdentifier(identifier: String?) {
        if let entry = entry {
            let entryReference = entry.serializeReference()
            EventualEntryPresenter.sharedPresenter.presentEntry(entryReference)
        }
    }
}
