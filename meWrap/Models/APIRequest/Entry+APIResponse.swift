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

func mappedEntries<T: Entry>(array: [[String:AnyObject]]?, container: Entry? = nil) -> [T] {
    guard let array = array where array.count != 0 else { return [] }
    var entries = [T]()
    for dictionary in array {
        if let entry: T = mappedEntry(dictionary, container: container) {
            entries.append(entry)
        }
    }
    return entries
}

func mappedEntry<T: Entry>(dictionary: [String:AnyObject]?, container: Entry? = nil) -> T? {
    guard let dictionary = dictionary else { return nil }
    if let entry = T.entry(T.uid(dictionary), locuid: T.locuid(dictionary)) {
        entry.map(dictionary, container: container)
        return entry
    } else {
        return nil
    }
}

extension Entry {
    
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
        let devices: [Device] = mappedEntries(dictionary[Keys.Devices] as? [[String : AnyObject]], container: self)
        if !devices.isEmpty {
            self.devices = Set(devices)
        }
        
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
    
    override class func locuid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Upload] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        createdAt <!= dictionary.dateForKey(Keys.ContributedAt)
        if let updatedAt = dictionary.dateForKey(Keys.LastTouchedAt) where updatedAt.later(self.updatedAt) {
            self.updatedAt = updatedAt
        }
        contributor <!= mappedEntry(dictionary[Keys.Contributor] as? [String:AnyObject])
    }
}

extension Wrap {
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Wrap] as? String
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        name <!= dictionary[Keys.Name]
        isPublic <!= dictionary["is_public"] as? Bool
        isRestrictedInvite <!= dictionary["is_restricted_invite"] as? Bool
        
        if let array = dictionary[Keys.Contributors] as? [[String:AnyObject]] {
            contributors <!= Set(mappedEntries(array)) as? Set<User>
        }
        
        contributor <!= mappedEntry(dictionary[Keys.Creator] as? [String:AnyObject])
        
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
        
        let _: [Candy] = mappedEntries(dictionary[Keys.Candies] as? [[String : AnyObject]], container: self)
    }
}

extension Candy {
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary[Keys.UID.Candy] as? String
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let uploading = uploading where uploading.type == Event.Update.rawValue {
            return
        }
        
        super.map(dictionary, container: container)
        
        editor <!= mappedEntry(dictionary[Keys.Editor] as? [String:AnyObject])
        editedAt <!= dictionary.dateForKey(Keys.EditedAt)
        
        if let type = dictionary[Keys.CandyType] as? Int {
            self.type <!= Int16(type)
        }
        
        let _: [Comment] = mappedEntries(dictionary[Keys.Comments] as? [[String : AnyObject]], container: self)
        
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
