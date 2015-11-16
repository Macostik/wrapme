//
//  Entry+API.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/5/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension Entry {
    
    class func mappedEntries(array: [[String:AnyObject]]) -> [Entry] {
        return mappedEntries(array, container: nil)
    }
    
    class func mappedEntries(array: [[String:AnyObject]], container: Entry?) -> [Entry] {
        if array.count == 0 {
            return []
        }
        var entries = [Entry]()
        for dictionary in array {
            if let entry = self.mappedEntry(dictionary, container: container) {
                entries.append(entry)
            }
        }
        return entries
    }
    
    class func mappedEntry(dictionary: [String:AnyObject]) -> Self? {
        return mappedEntry(dictionary, container: nil)
    }
    
    class func mappedEntry(dictionary: [String:AnyObject], container: Entry?) -> Self? {
        return mappedEntry(self, dictionary: dictionary, container: container)
    }
    
    class func mappedEntry<T>(type: T.Type, dictionary: [String:AnyObject], container: Entry?) -> T? {
        let uid = self.uid(dictionary)
        let locuid = self.locuid(dictionary)
        if let entry = self.entry(uid, locuid: locuid) {
            entry.map(dictionary, container: container)
            return entry as? T
        } else {
            return nil
        }
    }
    
    class func uid(dictionary: [String:AnyObject]) -> String? {
        return nil
    }
    
    class func locuid(dictionary: [String:AnyObject]) -> String? {
        return nil
    }
    
    func map(dictionary: [String:AnyObject]) {
        map(dictionary, container: nil)
    }
    
    func map(dictionary: [String:AnyObject], container: Entry?) {
        
        if let createdAt = dictionary.dateForKey(WLContributedAtKey) where self.createdAt != createdAt {
            self.createdAt = createdAt
        }
        if let updatedAt = dictionary.dateForKey(WLLastTouchedAtKey) where updatedAt.later(self.updatedAt) {
            self.updatedAt = updatedAt
        }
        if let uid = self.dynamicType.uid(dictionary) where uid != self.identifier {
            self.identifier = uid
        }
        if let locuid = self.dynamicType.locuid(dictionary) where locuid != self.uploadIdentifier {
            self.uploadIdentifier = locuid
        }
    }
    
    func editPicture(editedPicture: Asset?) {
        if let picture = editedPicture where self.picture != picture {
            self.picture = picture
        }
    }
}

extension User {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[WLUserUIDKey] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let signInCount = dictionary[WLSignInCountKey] as? Int {
            let firstTimeUse = signInCount == 1
            if firstTimeUse != self.firstTimeUse {
                self.firstTimeUse = firstTimeUse
            }
        }
        
        if let name = dictionary[WLNameKey] as? String where self.name != name {
            self.name = name
        }
        
        if let urls = dictionary[WLAvatarURLsKey] as? [String:String] {
            editPicture(self.picture?.edit(urls, metrics: AssetMetrics.avatarMetrics))
        }

        if let devices = dictionary[WLDevicesKey] as? [[String : AnyObject]] {
            let devices = Device.mappedEntries(devices, container: self)
            if self.devices != devices {
                self.devices = NSSet(array: devices)
            }
        }
        
        super.map(dictionary, container: container)
    }
}

extension Device {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[WLDeviceIDKey] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let name = dictionary["device_name"] as? String where self.name != name {
            self.name = name
        }
        
        if let phone = dictionary[WLFullPhoneNumberKey] as? String where self.phone != phone {
            self.phone = phone
        }
        
        if let phone = dictionary[WLFullPhoneNumberKey] as? String where self.phone != phone {
            self.phone = phone
        }
        
        if let phone = dictionary[WLFullPhoneNumberKey] as? String where self.phone != phone {
            self.phone = phone
        }
        
        if let activated = dictionary["activated"] as? Bool where self.activated != activated {
            self.activated = activated
        }
        
        if let invitedAt = dictionary.dateForKey("invited_at_in_epoch") where self.invitedAt != invitedAt {
            self.invitedAt = invitedAt
        }
        
        if let invitedBy = dictionary["invited_by_user_uid"] as? String where self.invitedBy != invitedBy {
            self.invitedBy = invitedBy
        }
        
        if let container = container as? User where container != self.owner {
            self.owner = container
        }
        
        super.map(dictionary, container: container)
    }
}

extension Contribution {
    override class func locuid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[WLUploadUIDKey] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let dictionary = dictionary[WLContributorKey] as? [String:AnyObject] {
            if let contributor = User.mappedEntry(dictionary) where self.contributor != contributor {
                self.contributor = contributor
            }
        }
        
        if let dictionary = dictionary[WLEditorKey] as? [String:AnyObject] {
            if let editor = User.mappedEntry(dictionary) where self.editor != editor {
                self.editor = editor
            }
        }
        
        if let editedAt = dictionary.dateForKey(WLEditedAtKey) where self.editedAt != editedAt {
            self.editedAt = editedAt
        }
        
        super.map(dictionary, container: container)
    }
}

extension Wrap {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[WLWrapUIDKey] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let name = dictionary[WLNameKey] as? String where self.name != name {
            self.name = name
        }
        
        if let isPublic = dictionary["is_public"] as? Bool where self.isPublic != isPublic {
            self.isPublic = isPublic
        }
        
        if let isRestrictedInvite = dictionary["is_restricted_invite"] as? Bool where self.isRestrictedInvite != isRestrictedInvite {
            self.isRestrictedInvite = isRestrictedInvite
        }
        
        if let array = dictionary[WLContributorsKey] as? [[String:AnyObject]] {
            let contributors = Set(User.mappedEntries(array))
            if (self.contributors?.isEqualToSet(contributors) ?? false) == false {
                self.contributors = contributors
            }
        }
        
        if let dictionary = dictionary[WLCreatorKey] as? [String:AnyObject] {
            if let contributor = User.mappedEntry(dictionary) where self.contributor != contributor {
                self.contributor = contributor
            }
        }
        
        if let currentUser = User.currentUser {
            let isContributing = contributors?.containsObject(currentUser) ?? false
            if isPublic {
                if let isFollowing = dictionary["is_following"] as? Bool {
                    if isFollowing && !isContributing {
                        mutableContributors.addObject(currentUser)
                    } else if (!isFollowing && isContributing) {
                        mutableContributors.removeObject(currentUser)
                    }
                }
            } else if !isContributing {
                mutableContributors.addObject(currentUser)
            }
        }
        
        if let array = dictionary[WLCandiesKey] as? [[String : AnyObject]] {
            Candy.mappedEntries(array, container: self)
        }
        
        super.map(dictionary, container: container)
    }
}

extension Candy {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[WLCandyUIDKey] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let type = dictionary[WLCandyTypeKey] as? Int {
            let type = Int16(type)
            if self.type != type {
                self.type = type
            }
        }
        
        if let array = dictionary[WLCommentsKey] as? [[String : AnyObject]] {
            Comment.mappedEntries(array, container: self)
        }
        switch mediaType {
        case .Photo:
            if let urls = dictionary[WLMediaURLsKey] as? [String : String] {
                editPicture(picture?.edit(urls, metrics: AssetMetrics.imageMetrics))
            } else if let urls = dictionary[WLImageURLsKey] as? [String : String] {
                editPicture(picture?.edit(urls, metrics: AssetMetrics.imageMetrics))
            }
            break
        case .Video:
            if let urls = dictionary[WLMediaURLsKey] as? [String : String] {
                editPicture(picture?.edit(urls, metrics: AssetMetrics.videoMetrics))
            } else if let urls = dictionary[WLVideoURLsKey] as? [String : String] {
                editPicture(picture?.edit(urls, metrics: AssetMetrics.videoMetrics))
            }
            break
        }
        
        if self.wrap == nil {
            if let wrap = container as? Wrap ?? Wrap.entry(dictionary[WLWrapUIDKey] as? String) where self.wrap != wrap {
                self.wrap = wrap
            }
        }
        
        if let commentCount = dictionary[WLCommentCountKey] as? Int {
            let commentCount = Int16(commentCount)
            if self.commentCount < commentCount {
                self.commentCount = commentCount
            }
        }
        
        super.map(dictionary, container: container)
    }
}

extension Message {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[WLMessageUIDKey] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let text = dictionary[WLContentKey] as? String where self.text != text {
            self.text = text
        }
        
        if self.wrap == nil {
            if let wrap = container as? Wrap ?? Wrap.entry(dictionary[WLWrapUIDKey] as? String) where self.wrap != wrap {
                self.wrap = wrap
            }
        }
        
        super.map(dictionary, container: container)
    }
}

extension Comment {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[WLCommentUIDKey] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let text = dictionary[WLContentKey] as? String where self.text != text {
            self.text = text
        }
        
        if self.candy == nil {
            if let candy = container as? Candy ?? Candy.entry(dictionary[WLCandyUIDKey] as? String) where self.candy != candy {
                self.candy = candy
            }
        }
        
        super.map(dictionary, container: container)
    }
}
