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
    case CriticalUpdate        = 1400
    case InviteeSignUp         = 1500
    
    func isDelete() -> Bool {
        switch self {
        case .WrapDelete, .CommentDelete, .CandyDelete: return true
        default: return false
        }
    }
}

class UpdateAvailableNotification: Notification {
    override func presentWithIdentifier(identifier: String?, completionHandler: (() -> ())?) {
        if let url = "itms-apps://itunes.apple.com/app/id\(Constants.appStoreID)".URL {
            UIApplication.sharedApplication().openURL(url)
        }
        completionHandler?()
    }
}

class Notification: CustomStringConvertible {
    var uid: String?
    var body: [String:AnyObject]?
    var originatedByCurrentUser = false
    var type: NotificationType = .ContributorAdd
    var isHistorycal = true
    
    private class func parseNotificationType(data: [String:AnyObject]) -> NotificationType? {
        guard let type = data["msg_type"] as? Int else { return nil }
        return NotificationType(rawValue: type)
    }
    
    class func notificationWithMessage(message: AnyObject?) -> Notification? {
        guard let body = ((message as? PNMessageData)?.message ?? message) as? [String:AnyObject] else { return nil }
        return notificationWithBody(body)
    }
    
    class func notificationWithBody(body: [String:AnyObject]) -> Notification? {
        guard let type = parseNotificationType(body) else { return nil }
        switch type {
        case .ContributorAdd: return ContributorAddNotification(type: type, body: body)
        case .ContributorDelete: return ContributorDeleteNotification(type: type, body: body)
        case .WrapDelete: return WrapDeleteNotification(type: type, body: body)
        case .WrapUpdate: return WrapUpdateNotification(type: type, body: body)
        case .CandyAdd: return CandyAddNotification(type: type, body: body)
        case .CandyDelete: return CandyDeleteNotification(type: type, body: body)
        case .CandyUpdate: return CandyUpdateNotification(type: type, body: body)
        case .MessageAdd: return MessageAddNotification(type: type, body: body)
        case .CommentAdd: return CommentAddNotification(type: type, body: body)
        case .CommentDelete: return CommentDeleteNotification(type: type, body: body)
        case .UserUpdate: return UserUpdateNotification(type: type, body: body)
        case .UpdateAvailable, .CriticalUpdate: return UpdateAvailableNotification(type: type, body: body)
        case .LiveBroadcast: return LiveBroadcastNotification(type: type, body: body)
        case .InviteeSignUp: return Notification(type: type, body: body)
        }
    }
    
    convenience init(type: NotificationType, body: [String:AnyObject]) {
        self.init()
        self.body = body
        self.uid = body["msg_uid"] as? String
        self.type = type
        setup(body)
    }
    
    internal func setup(body: [String:AnyObject]) {
        if let originator = body["originator"] as? [String:AnyObject] {
            let userID = originator["user_uid"] as? String
            let deviceID = originator["device_uid"] as? String
            originatedByCurrentUser = userID == User.currentUser?.uid && deviceID == Authorization.current.deviceUID
        }
    }
    
    func fetch(success: Block, failure: FailureBlock) { success() }
    
    func submit() { }
    
    func handle(success: Block, failure: FailureBlock) {
        fetch({ _ in
            self.submit()
            success()
            }, failure: failure)
    }
    
    var description: String { return "\(type.rawValue): \(uid ?? "")" }
    
    func canBeHandled() -> Bool { return Authorization.active && !originatedByCurrentUser }
    
    func presentWithIdentifier(identifier: String?, completionHandler: (() -> ())? = nil) {
        completionHandler?()
    }
    
    func getEntry() -> Entry? { return nil }
}

class EntryNotification<T: Entry>: Notification {
    internal var entryUid: String?
    internal var entryLocUid: String?
    internal var containerUid: String?
    internal var entryData: [String:AnyObject]?
    var inserted = false
    
    internal func dataKey() -> String { return "" }
    
    override func setup(body: [String : AnyObject]) {
        super.setup(body)
        setupEntryData(body)
    }
    
    internal func setupEntryData(body: [String : AnyObject]) {
        entryData = body[dataKey()] as? [String:AnyObject]
        let parseData = entryData ?? body
        entryUid = T.uid(parseData)
        entryLocUid = T.locuid(parseData)
        containerUid = T.containerType()?.uid(parseData)
    }
    
    internal var _entry: T?
    var entry: T? {
        createEntryIfNeeded()
        return _entry
    }
    
    override func getEntry() -> Entry? {
        createEntryIfNeeded()
        return _entry
    }
    
    internal func shouldCreateEntry() -> Bool {
        if type.isDelete() {
            return EntryContext.sharedContext.hasEntry(T.entityName(), uid: entryUid)
        } else {
            return true
        }
    }
    
    internal func createEntryIfNeeded() {
        if _entry == nil && shouldCreateEntry() {
            createEntry()
        }
    }
    
    internal func mapEntry(entry: T, data: [String:AnyObject]) {
        entry.map(data)
    }
    
    internal func createEntry() {
        guard let entry: T = T.entry(entryUid, locuid:entryLocUid) else { return }
        
        if let data = entryData {
            mapEntry(entry, data: data)
        }
        
        _entry = entry
        inserted = entry.inserted
        
        if let locuid = entry.locuid {
            Logger.log("Notification \(self). Created entry \(entry). Number of entries with the same upload_uid \(FetchRequest<T>().query("locuid == %@", locuid).count())")
        } else {
            Logger.log("Notification \(self). Created entry \(entry). No upload_uid")
        }
    }
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        success()
    }
    
    override var description: String {
        return "\(type.rawValue): \(entryUid ?? "")"
    }
    
    override func canBeHandled() -> Bool { return Authorization.active && !originatedByCurrentUser }
    
    override func presentWithIdentifier(identifier: String?, completionHandler: (() -> ())? = nil) {
        if let entry = entry {
            AuthorizedExecutor.presentEntry(entry, completionHandler: completionHandler)
        } else {
            completionHandler?()
        }
    }
}
