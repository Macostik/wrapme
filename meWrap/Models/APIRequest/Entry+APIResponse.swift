//
//  Entry+API.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/5/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

infix operator <!= {}

func <!= <T: Equatable>(inout left: T?, right: T?) {
    if let right = right where left != right {
        left = right
    }
}

func <!= <T: Equatable>(inout left: T?, right: AnyObject?) {
    left <!= right as? T
}

func <!= <T: Equatable>(inout left: T, right: T?) {
    if let right = right where left != right {
        left = right
    }
}

func <!= <T: Entry>(inout left: T?, right: T?) {
    if let right = right where left != right {
        left = right
    }
}

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
    
    class func prefetchDescriptors(descriptors: NSMutableDictionary, inArray array: [[String : AnyObject]]?) {
        guard let array = array else { return }
        for dictionary in array {
            prefetchDescriptors(descriptors, inDictionary: dictionary)
        }
    }
    
    class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]?) {
        if let dictionary = dictionary, let uid = self.uid(dictionary) where descriptors[uid] == nil {
            descriptors[uid] = EntryDescriptor(name: entityName(), uid: uid, locuid: self.locuid(dictionary))
        }
    }
    
    class func mappedEntries(array: [[String:AnyObject]]?) -> [Entry] {
        return mappedEntries(array, container: nil)
    }
    
    class func mappedEntries(array: [[String:AnyObject]]?, container: Entry?) -> [Entry] {
        guard let array = array where array.count != 0 else { return [] }
        var entries = [Entry]()
        for dictionary in array {
            if let entry = self.mappedEntry(dictionary, container: container) {
                entries.append(entry)
            }
        }
        return entries
    }
    
    class func mappedEntry(dictionary: [String:AnyObject]?) -> Self? {
        return mappedEntry(dictionary, container: nil)
    }
    
    class func mappedEntry(dictionary: [String:AnyObject]?, container: Entry?) -> Self? {
        guard let dictionary = dictionary else { return nil }
        if let entry = self.entry(self.uid(dictionary), locuid: self.locuid(dictionary)) {
            entry.map(dictionary, container: container)
            return entry
        } else {
            return nil
        }
    }
    
    class func uid(dictionary: [String:AnyObject]) -> String? { return nil }
    
    class func locuid(dictionary: [String:AnyObject]) -> String? { return nil }
    
    func map(dictionary: [String:AnyObject]) {
        map(dictionary, container: nil)
    }
    
    func map(dictionary: [String:AnyObject], container: Entry?) {
        uid <!= self.dynamicType.uid(dictionary)
        locuid <!= self.dynamicType.locuid(dictionary)
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
            firstTimeUse <!= signInCount == 1
        }
        
        name <!= dictionary[Keys.Name]
        
        if let urls = dictionary[Keys.AvatarURLs] as? [String:String] {
            avatar <!= self.avatar?.edit(urls, metrics: AssetMetrics.avatarMetrics)
        }
        
        invitedAt <!= dictionary.dateForKey("invited_at_in_epoch")
        Device.mappedEntries(dictionary[Keys.Devices] as? [[String : AnyObject]], container: self)
        
        if let remoteLogging = dictionary["remote_logging"] as? Bool where current {
            NSUserDefaults.standardUserDefaults().remoteLogging = remoteLogging
        }
    }
}

extension Device {
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Device] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        name <!= dictionary["device_name"]
        phone <!= dictionary[Keys.FullPhoneNumber]
        activated <!= dictionary["activated"] as? Bool
        owner <!= container
    }
}

extension Contribution {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(descriptors, inDictionary: dictionary?["contributor"] as? [String:AnyObject])
    }
    
    override class func locuid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Upload] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        createdAt <!= dictionary.dateForKey(Keys.ContributedAt)
        if let updatedAt = dictionary.dateForKey(Keys.LastTouchedAt) where updatedAt.later(self.updatedAt) {
            self.updatedAt = updatedAt
        }
        contributor <!= User.mappedEntry(dictionary[Keys.Contributor] as? [String:AnyObject])
    }
}

extension Wrap {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(descriptors, inArray: dictionary?["contributors"] as? [[String:AnyObject]])
        User.prefetchDescriptors(descriptors, inDictionary: dictionary?["creator"] as? [String:AnyObject])
        Candy.prefetchDescriptors(descriptors, inArray: dictionary?["candies"] as? [[String:AnyObject]])
    }
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Wrap] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        name <!= dictionary[Keys.Name]
        isPublic <!= dictionary["is_public"] as? Bool
        isRestrictedInvite <!= dictionary["is_restricted_invite"] as? Bool
        
        if let array = dictionary[Keys.Contributors] as? [[String:AnyObject]] {
            contributors <!= Set(User.mappedEntries(array)) as? Set<User>
        }
        
        contributor <!= User.mappedEntry(dictionary[Keys.Creator] as? [String:AnyObject])
        
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
        
        Candy.mappedEntries(dictionary[Keys.Candies] as? [[String : AnyObject]], container: self)
    }
}

extension Candy {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(descriptors, inDictionary: dictionary?["editor"] as? [String:AnyObject])
        Comment.prefetchDescriptors(descriptors, inArray: dictionary?["comments"] as? [[String:AnyObject]])
    }
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Candy] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        super.map(dictionary, container: container)
        
        editor <!= User.mappedEntry(dictionary[Keys.Editor] as? [String:AnyObject])
        editedAt <!= dictionary.dateForKey(Keys.EditedAt)
        
        if let type = dictionary[Keys.CandyType] as? Int {
            self.type <!= Int16(type)
        }
        
        Comment.mappedEntries(dictionary[Keys.Comments] as? [[String : AnyObject]], container: self)
        
        let asset = self.asset?.editCandyAsset(dictionary, mediaType: mediaType)
        if asset != self.asset {
            self.asset = asset
        }
        
        if wrap == nil {
            wrap <!= container as? Wrap ?? Wrap.entry(dictionary[Keys.UID.Wrap] as? String)
        }
        
        if let commentCount = dictionary[Keys.CommentCount] as? Int {
            self.commentCount <!= Int16(commentCount)
        }
    }
}

extension Message {
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Message] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        text <!= dictionary[Keys.Content]
        if wrap == nil {
            wrap <!= container as? Wrap ?? Wrap.entry(dictionary[Keys.UID.Wrap] as? String)
        }
    }
}

extension Comment {
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Comment] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        text <!= dictionary[Keys.Content]
        if self.candy == nil {
            self.candy <!= container as? Candy ?? Candy.entry(dictionary[Keys.UID.Candy] as? String)
        }
    }
}
