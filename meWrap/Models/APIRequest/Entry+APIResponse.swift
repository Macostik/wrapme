//
//  Entry+API.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/5/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension Entry {
    
    class func prefetchArray(array: [[String : AnyObject]]) -> [[String : AnyObject]] {
        let descriptors = NSMutableDictionary()
        prefetchDescriptors(descriptors, inArray:array)
        EntryContext.sharedContext.fetchEntries(descriptors.allValues as! [EntryDescriptor])
        return array
    }
    
    class func prefetchDictionary(dictionary: [String : AnyObject]) -> [String : AnyObject] {
        let descriptors = NSMutableDictionary()
        prefetchDescriptors(descriptors, inDictionary: dictionary)
        EntryContext.sharedContext.fetchEntries(descriptors.allValues as! [EntryDescriptor])
        return dictionary
    }
    
    class func prefetchDescriptors(descriptors: NSMutableDictionary, inArray array: [[String : AnyObject]]) {
        for dictionary in array {
            prefetchDescriptors(descriptors, inDictionary: dictionary)
        }
    }
    
    class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]) {
        if let uid = self.uid(dictionary) where descriptors[uid] == nil {
            let descriptor = EntryDescriptor(name: entityName(), uid: uid)
            descriptor.locuid = self.locuid(dictionary)
            descriptors[uid] = descriptor
        }
    }
    
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
        if let uid = self.dynamicType.uid(dictionary) where uid != self.uid {
            self.uid = uid
        }
        if let locuid = self.dynamicType.locuid(dictionary) where locuid != self.locuid {
            self.locuid = locuid
        }
    }
    
    func update(dictionary: [String : AnyObject]) -> Self {
        map(dictionary)
        if updated {
            notifyOnUpdate(.Default)
        }
        return self
    }
}

extension User {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.User] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        if let signInCount = dictionary[Keys.SignInCount] as? Int {
            let firstTimeUse = signInCount == 1
            if firstTimeUse != self.firstTimeUse {
                self.firstTimeUse = firstTimeUse
            }
        }
        
        if let name = dictionary[Keys.Name] as? String where self.name != name {
            self.name = name
        }
        
        if let urls = dictionary[Keys.AvatarURLs] as? [String:String] {
            let avatar = self.avatar?.edit(urls, metrics: AssetMetrics.avatarMetrics)
            if avatar != self.avatar {
                self.avatar = avatar
            }
        }
        
        if let invitedAt = dictionary.dateForKey("invited_at_in_epoch") where self.invitedAt != invitedAt {
            self.invitedAt = invitedAt
        }

        if let devices = dictionary[Keys.Devices] as? [[String : AnyObject]] {
            Device.mappedEntries(devices, container: self)
        }
    }
}

extension Device {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Device] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        if let name = dictionary["device_name"] as? String where self.name != name {
            self.name = name
        }
        
        if let phone = dictionary[Keys.FullPhoneNumber] as? String where self.phone != phone {
            self.phone = phone
        }
        
        if let activated = dictionary["activated"] as? Bool where self.activated != activated {
            self.activated = activated
        }
        
        if let container = container as? User where container != self.owner {
            self.owner = container
        }
    }
}

extension Contribution {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        if let contributor = dictionary["contributor"] as? [String:AnyObject] {
            User.prefetchDescriptors(descriptors, inDictionary: contributor)
        }
    }
    
    override class func locuid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Upload] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        if let createdAt = dictionary.dateForKey(Keys.ContributedAt) where self.createdAt != createdAt {
            self.createdAt = createdAt
        }
        if let updatedAt = dictionary.dateForKey(Keys.LastTouchedAt) where updatedAt.later(self.updatedAt) {
            self.updatedAt = updatedAt
        }
        
        if let dictionary = dictionary[Keys.Contributor] as? [String:AnyObject] {
            if let contributor = User.mappedEntry(dictionary) where self.contributor != contributor {
                self.contributor = contributor
            }
        }
    }
}

extension Wrap {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        
        if let contributors = dictionary["contributors"] as? [[String:AnyObject]] {
            User.prefetchDescriptors(descriptors, inArray: contributors)
        }
        
        if let creator = dictionary["creator"] as? [String:AnyObject] {
            User.prefetchDescriptors(descriptors, inDictionary: creator)
        }
        
        if let candies = dictionary["candies"] as? [[String:AnyObject]] {
            Candy.prefetchDescriptors(descriptors, inArray: candies)
        }
    }
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Wrap] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        if let name = dictionary[Keys.Name] as? String where self.name != name {
            self.name = name
        }
        
        if let isPublic = dictionary["is_public"] as? Bool where self.isPublic != isPublic {
            self.isPublic = isPublic
        }
        
        if let isRestrictedInvite = dictionary["is_restricted_invite"] as? Bool where self.isRestrictedInvite != isRestrictedInvite {
            self.isRestrictedInvite = isRestrictedInvite
        }
        
        if let array = dictionary[Keys.Contributors] as? [[String:AnyObject]] {
            let contributors = Set(User.mappedEntries(array)) as! Set<User>
            if self.contributors != contributors {
                self.contributors = contributors
            }
        }
        
        if let dictionary = dictionary[Keys.Creator] as? [String:AnyObject] {
            if let contributor = User.mappedEntry(dictionary) where self.contributor != contributor {
                self.contributor = contributor
            }
        }
        
        if let currentUser = User.currentUser {
            let isContributing = contributors.contains(currentUser)
            if isPublic {
                if let isFollowing = dictionary["is_following"] as? Bool {
                    if isFollowing && !isContributing {
                        contributors.insert(currentUser)
                    } else if (!isFollowing && isContributing) {
                        contributors.remove(currentUser)
                    }
                }
            } else if !isContributing {
                contributors.insert(currentUser)
            }
        }
        
        if let array = dictionary[Keys.Candies] as? [[String : AnyObject]] {
            Candy.mappedEntries(array, container: self)
        }
    }
}

extension Candy {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        if let editor = dictionary["editor"] as? [String:AnyObject] {
            User.prefetchDescriptors(descriptors, inDictionary: editor)
        }
        if let comments = dictionary["comments"] as? [[String:AnyObject]] {
            Comment.prefetchDescriptors(descriptors, inArray: comments)
        }
    }
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Candy] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let updatedAt = dictionary.dateForKey(Keys.LastTouchedAt) where uploaded && updatedAt < self.updatedAt {
            return
        }
        
        super.map(dictionary, container: container)
        
        if let dictionary = dictionary[Keys.Editor] as? [String:AnyObject] {
            if let editor = User.mappedEntry(dictionary) where self.editor != editor {
                self.editor = editor
            }
            if let editedAt = dictionary.dateForKey(Keys.EditedAt) where self.editedAt != editedAt {
                self.editedAt = editedAt
            }
        }
        
        if let type = dictionary[Keys.CandyType] as? Int {
            let type = Int16(type)
            if self.type != type {
                self.type = type
            }
        }
        
        if let array = dictionary[Keys.Comments] as? [[String : AnyObject]] {
            Comment.mappedEntries(array, container: self)
        }
        var asset = self.asset
        switch mediaType {
        case .Photo:
            if let urls = dictionary[Keys.MediaURLs] as? [String : String] {
                asset = asset?.edit(urls, metrics: AssetMetrics.imageMetrics)
            } else if let urls = dictionary[Keys.ImageURLs] as? [String : String] {
                asset = asset?.edit(urls, metrics: AssetMetrics.imageMetrics)
            }
            break
        case .Video:
            if let urls = dictionary[Keys.MediaURLs] as? [String : String] {
                asset = asset?.edit(urls, metrics: AssetMetrics.videoMetrics)
            } else if let urls = dictionary[Keys.VideoURLs] as? [String : String] {
                asset = asset?.edit(urls, metrics: AssetMetrics.videoMetrics)
            }
            break
        }
        
        if asset != self.asset {
            self.asset = asset
        }
        
        if self.wrap == nil {
            if let wrap = container as? Wrap ?? Wrap.entry(dictionary[Keys.UID.Wrap] as? String) where self.wrap != wrap {
                self.wrap = wrap
            }
        }
        
        if let commentCount = dictionary[Keys.CommentCount] as? Int {
            let commentCount = Int16(commentCount)
            if self.commentCount != commentCount {
                self.commentCount = commentCount
            }
        }
    }
}

extension Message {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Message] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        if let text = dictionary[Keys.Content] as? String where self.text != text {
            self.text = text
        }
        
        if self.wrap == nil {
            if let wrap = container as? Wrap ?? Wrap.entry(dictionary[Keys.UID.Wrap] as? String) where self.wrap != wrap {
                self.wrap = wrap
            }
        }
    }
}

extension Comment {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Comment] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        if let text = dictionary[Keys.Content] as? String where self.text != text {
            self.text = text
        }
        
        if self.candy == nil {
            if let candy = container as? Candy ?? Candy.entry(dictionary[Keys.UID.Candy] as? String) where self.candy != candy {
                self.candy = candy
            }
        }
    }
}
