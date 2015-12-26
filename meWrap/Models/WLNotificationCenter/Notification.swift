//
//  Notification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

@objc enum NotificationType: Int {
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
    case Engagement            = 99
}

class Notification: NSObject {
    var type: NotificationType = .ContributorAdd
    var event: Event = .Add
    var uid: String?
    var playSound: Bool {
        guard let entry = entry where isSoundAllowed else {
            return false
        }
        switch (type) {
        case .ContributorAdd, .MessageAdd, .CommentAdd:
            return entry.notifiableForNotification(self) ?? false
        default:
            return false
        }

    }
    var isSoundAllowed = false
    var presentable: Bool {
        return event != .Delete
    }
    var date: NSDate?
    var publishedAt: NSDate?
    var data: [String:AnyObject]?
    var requester: User?
    var descriptor: EntryDescriptor?
    var trimmed = false
    var inserted = false
    var originatedByCurrentUser = false
    
    convenience init?(message: AnyObject?) {
        var data: [String:AnyObject]?
        var timetoken: NSNumber?
        if let message = message as? PNMessageData {
            data = message.message as? [String:AnyObject]
            timetoken = message.timetoken
        } else if let message = message as? [String:AnyObject] {
            data = message["message"] as? [String:AnyObject]
            timetoken = message["timetoken"] as? NSNumber
        }
        
        if let data = data, let timetoken = timetoken {
            self.init(data: data, date: NSDate.dateWithTimetoken(timetoken))
        } else {
            return nil
        }
    }
    
    convenience init?(data: [String:AnyObject], date: NSDate?) {
        if let msg_type = data["msg_type"] as? Int, let type = NotificationType(rawValue: msg_type) {
            self.init(type: type, data: data, date: date)
        } else {
            return nil
        }
    }
    
    required init(type: NotificationType, data: [String:AnyObject], date: NSDate?) {
        self.type = type
        self.date = date
        self.data = data
        self.uid = data["msg_uid"] as? String
        super.init()
        setup(data)
    }
    
    private func setup(data: [String:AnyObject]) {
        publishedAt = data.dateForKey("msg_published_at")
        
        if let originator = data["originator"] as? [String:AnyObject] {
            let userID = originator["user_uid"] as? String
            let deviceID = originator["device_uid"] as? String
            originatedByCurrentUser = userID == User.currentUser?.uid && deviceID == Authorization.currentAuthorization.deviceUID
        }
        
        guard type != .UpdateAvailable else { return }
        
        isSoundAllowed = data["pn_apns"] != nil
        
        switch (type) {
        case .ContributorDelete, .CandyDelete, .WrapDelete, .CommentDelete:
            event = .Delete
            break
        case .ContributorAdd, .CandyAdd, .MessageAdd, .CommentAdd:
            event = .Add
            break
        case .UserUpdate, .WrapUpdate, .CandyUpdate:
            event = .Update
            break
        default: break
        }
        
        let descriptor = EntryDescriptor()
        var uid: String?
        var entryData: [String:AnyObject]?
        switch type {
        case .ContributorAdd, .ContributorDelete, .WrapDelete, .WrapUpdate:
            descriptor.name = Wrap.entityName()
            entryData = data["wrap"] as? [String:AnyObject]
            uid = Wrap.uid(entryData ?? data)
            descriptor.locuid = Wrap.locuid(entryData ?? data)
            break
        case .CandyAdd, .CandyDelete, .CandyUpdate:
            descriptor.name = Candy.entityName()
            entryData = data["candy"] as? [String:AnyObject]
            uid = Candy.uid(entryData ?? data)
            descriptor.locuid = Candy.locuid(entryData ?? data)
            break
        case .MessageAdd:
            descriptor.name = Message.entityName()
            entryData = data["chat"] as? [String:AnyObject]
            uid = Message.uid(entryData ?? data)
            descriptor.locuid = Message.locuid(entryData ?? data)
            break
        case .CommentAdd, .CommentDelete:
            descriptor.name = Comment.entityName()
            entryData = data["comment"] as? [String:AnyObject]
            uid = Comment.uid(entryData ?? data)
            descriptor.locuid = Comment.locuid(entryData ?? data)
            break
        case .UserUpdate:
            descriptor.name = User.entityName()
            entryData = data["user"] as? [String:AnyObject]
            uid = User.uid(entryData ?? data)
            descriptor.locuid = User.locuid(entryData ?? data)
            break
        default: break
        }
        descriptor.data = entryData
        trimmed = entryData == nil
        
        switch type {
        case .CandyAdd, .CandyDelete, .MessageAdd:
            descriptor.container = Wrap.uid(data)
            break
        case .CommentAdd, .CommentDelete:
            descriptor.container = Candy.uid(data)
            break
        default: break
        }
        
        if let uid = uid {
            descriptor.uid = uid
            self.descriptor = descriptor
        }
    }
    
    private var _entry: Entry?
    var entry: Entry? {
        if let entry = _entry {
            return entry
        } else {
            createEntry()
            return _entry
        }
    }
    
    private func createEntry() {
        guard let descriptor = descriptor else {
            return
        }
        
        if event == .Delete && !descriptor.entryExists() {
            return
        }
        
        guard let entry = EntryContext.sharedContext.entry(descriptor.name, uid:descriptor.uid, locuid:descriptor.locuid) else {
            return
        }
        if let data = descriptor.data {
            if type == .UserUpdate {
                Authorization.currentAuthorization.updateWithUserData(data)
            }
            if ((type == .CandyAdd || type == .CandyUpdate) && originatedByCurrentUser) {
                if let candy = entry as? Candy {
                    let oldPicture = candy.asset?.copy() as? Asset
                    entry.map(data)
                    if let newAsset = candy.asset {
                        oldPicture?.cacheForAsset(newAsset)
                    }
                    if candy.sortedComments().contains({ $0.uploading != nil }) {
                        Uploader.wrapUploader.start()
                    }
                }
                
            } else {
                entry.map(data)
            }
        }
        
        inserted = entry.inserted
        
        if entry.container == nil {
            if let name = entry.dynamicType.containerEntityName(), let uid = descriptor.container {
                entry.container = EntryContext.sharedContext.entry(name, uid: uid, locuid: nil, allowInsert: false)
            }
        }
        
        _entry = entry;
    }
    
    func prepare() {
        guard let entry = entry else { return }
        
        switch event {
        case .Add:
            entry.prepareForAddNotification(self)
        case .Update:
            entry.prepareForUpdateNotification(self)
        case .Delete:
            entry.prepareForDeleteNotification(self)
        }
    }

    func fetch(success: Block, failure: FailureBlock) {
        guard let entry = entry else {
            success()
            return
        }
        
        switch event {
        case .Add:
            entry.fetchAddNotification(self, success: success, failure: failure)
        case .Update:
            entry.fetchUpdateNotification(self, success: success, failure: failure)
        case .Delete:
            entry.fetchDeleteNotification(self, success: success, failure: failure)
        }
    }
    
    func finalizeNotification() {
        guard let entry = entry else { return }
        
        switch event {
        case .Add:
            entry.finalizeAddNotification(self)
        case .Update:
            entry.finalizeUpdateNotification(self)
        case .Delete:
            entry.finalizeDeleteNotification(self)
        }
    }
    
    func handle(success: Block, failure: FailureBlock) {
        prepare()
        fetch({ () -> Void in
            self.finalizeNotification()
            success()
            }, failure: failure)
    }
    
    override var description: String {
        return "\(type.rawValue): \(descriptor?.uid ?? "")"
    }
}

extension Entry {
    
    func notifiableForNotification(notification: Notification) -> Bool {
        return false
    }
    
    func markAsUnreadIfNeededForNotification(notification: Notification) {
        if notifiableForNotification(notification) {
            markAsUnread(true)
        }
    }
    
    func prepareForAddNotification(notification: Notification) {
    
    }
    
    func prepareForUpdateNotification(notification: Notification) {
    
    }
    
    func prepareForDeleteNotification(notification: Notification) {
    
    }
    
    func fetchAddNotification(notification: Notification, success: Block, failure: FailureBlock) {
        recursivelyFetchIfNeeded(success, failure: failure)
    }
    
    func fetchUpdateNotification(notification: Notification, success: Block, failure: FailureBlock) {
        if notification.trimmed {
            fetch({ (_) -> Void in
                success()
                }, failure: failure)
        } else {
            success()
        }
    }
    
    func fetchDeleteNotification(notification: Notification, success: Block, failure: FailureBlock) {
        success()
    }
    
    func finalizeAddNotification(notification: Notification) {
        notifyOnAddition()
    }
    
    func finalizeUpdateNotification(notification: Notification) {
        notifyOnUpdate(.Default)
    }
    
    func finalizeDeleteNotification(notification: Notification) {
        remove()
    }
}

extension Contribution {
    override func notifiableForNotification(notification: Notification) -> Bool {
        if notification.event == .Add {
            return !(self.contributor?.current ?? true)
        } else if notification.event == .Update {
            return !(self.editor?.current ?? true)
        } else {
            return false
        }
    }
}

extension Wrap {
    override func notifiableForNotification(notification: Notification) -> Bool {
        if notification.event == .Add {
            guard let data = notification.data else { return false }
            guard let contributor = contributor else { return false }
            guard let currentUser = User.currentUser else { return false }
            var uid: String?
            if let _uid = data["user_uid"] as? String {
                uid = _uid
            } else if let _uid = data["user"]?["user_uid"] as? String {
                uid = _uid
            }
            return !contributor.current && uid == currentUser.uid && notification.requester != currentUser
        } else {
            return super.notifiableForNotification(notification)
        }

    }

    override func fetchAddNotification(notification: Notification, success: Block, failure: FailureBlock) {
        guard let data = notification.data else { return }
        let userData = data["user"] as? [String: AnyObject]
        let user = userData != nil ? User.mappedEntry(userData!) : User.entry(data["user_uid"] as? String)
        if let user = user where !(contributors?.containsObject(user) ?? false) {
            mutableContributors.addObject(user)
        }
        if let inviter = data["inviter"] as? [String: AnyObject] {
            notification.requester = User.mappedEntry(inviter)
        }
        super.fetchAddNotification(notification, success:success, failure:failure)
    }
    
    override func finalizeAddNotification(notification: Notification) {
        if isPublic && !notification.inserted {
            notifyOnUpdate(.ContributorsChanged)
        } else {
            notifyOnAddition()
        }
    }
    
    override func finalizeDeleteNotification(notification: Notification) {
        guard let data = notification.data else { return }
        let userData = data["user"] as? [String: AnyObject]
        if let user = userData != nil ? User.mappedEntry(userData!) : User.entry(data["user_uid"] as? String) {
            if (notification.type == .WrapDelete || (user.current && !isPublic)) {
                super.finalizeDeleteNotification(notification)
            } else {
                mutableContributors.removeObject(user)
                notifyOnUpdate(.ContributorsChanged)
            }
        }
    }
}

extension Candy {
    
    override func fetchAddNotification(notification: Notification, success: Block, failure: FailureBlock) {
        super.fetchAddNotification(notification, success: { [weak self] () -> Void in
            if let asset = self?.asset {
                asset.fetch(success)
            } else {
                success()
            }
            }, failure: failure)
    }

    override func fetchUpdateNotification(notification: Notification, success: Block, failure: FailureBlock) {
        super.fetchUpdateNotification(notification, success: { [weak self] () -> Void in
            if let asset = self?.asset {
                asset.fetch(success)
            } else {
                success()
            }
            }, failure: failure)
    }

    override func finalizeAddNotification(notification: Notification) {
        if notification.inserted {
            markAsUnreadIfNeededForNotification(notification)
        }
        super.finalizeAddNotification(notification)
    }
    
    override func finalizeUpdateNotification(notification: Notification) {
        markAsUnreadIfNeededForNotification(notification)
        super.finalizeUpdateNotification(notification)
    }
    
    override func finalizeDeleteNotification(notification: Notification) {
        super.finalizeDeleteNotification(notification)
        if let wrap = wrap where wrap.valid && wrap.candies?.count < Constants.recentCandiesLimit {
            wrap.fetch(Wrap.ContentTypeRecent, success: nil, failure: nil)
        }
    }
}

extension Message {
    override func finalizeAddNotification(notification: Notification) {
        if (notification.inserted) {
            markAsUnreadIfNeededForNotification(notification)
        }
        super.finalizeAddNotification(notification)
    }
}

extension Comment {
    
    override func finalizeAddNotification(notification: Notification) {
        guard let candy = candy else {
            return
        }
        if candy.valid {
            candy.commentCount = Int16(candy.comments?.count ?? 0)
        }
        if (notification.inserted) {
            markAsUnreadIfNeededForNotification(notification)
        }
        super.finalizeAddNotification(notification)
    }
    
    override func notifiableForNotification(notification: Notification) -> Bool {
        if (notification.event != .Add) {
            return super.notifiableForNotification(notification)
        }
        
        guard let currentUser = User.currentUser, let candy = candy else {
            return false
        }
        
        if self.contributor == currentUser {
            return false
        } else {
            if candy.contributor == currentUser {
                return true
            } else {
                for comment in candy.sortedComments() {
                    if (comment.contributor == currentUser) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}
