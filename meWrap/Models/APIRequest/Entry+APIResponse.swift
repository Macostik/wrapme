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
        return dictionary.get(Keys.UID.User)
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        if let signInCount = dictionary[Keys.SignInCount] as? Int {
            firstTimeUse <!= signInCount == 1
        }
        
        name <!= dictionary[Keys.Name]
        
        if let urls = dictionary[Keys.AvatarURLs] as? [String:String] {
            avatar <!= self.avatar?.edit(urls, metrics: AssetMetrics.avatarMetrics, type: .Photo)
        }
        
        invitedAt <!= dictionary.dateForKey("invited_at_in_epoch")
        let devices: [Device] = mappedEntries(dictionary.get(Keys.Devices), container: self)
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
        return dictionary.get(Keys.UID.Device)
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
        return dictionary.get(Keys.UID.Upload)
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        createdAt <!= dictionary.dateForKey(Keys.ContributedAt)
        if let updatedAt = dictionary.dateForKey(Keys.LastTouchedAt) where updatedAt.later(self.updatedAt) {
            self.updatedAt = updatedAt
        }
        contributor <!= mappedEntry(dictionary.get(Keys.Contributor))
    }
}

extension Wrap {
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary.get(Keys.UID.Wrap)
    }
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        super.map(dictionary, container: container)
        
        name <!= dictionary[Keys.Name]
        isPublic <!= dictionary["is_public"] as? Bool
        isRestrictedInvite <!= dictionary["is_restricted_invite"] as? Bool
        
        if let array = dictionary[Keys.Contributors] as? [[String:AnyObject]] {
            contributors <!= Set(mappedEntries(array)) as? Set<User>
        }
        
        contributor <!= mappedEntry(dictionary.get(Keys.Creator))
        
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
        
        let _: [Candy] = mappedEntries(dictionary.get(Keys.Candies), container: self)
    }
}

extension Candy {
    
    override class func uid(dictionary: [String:AnyObject]) -> String? {
        return dictionary.get(Keys.UID.Candy)
    }
    
    override func map(dictionary: [String : AnyObject], container: Entry?) {
        
        if let uploading = uploading where uploading.type == Event.Update.rawValue {
            return
        }
        
        super.map(dictionary, container: container)
        
        editor <!= mappedEntry(dictionary.get(Keys.Editor))
        editedAt <!= dictionary.dateForKey(Keys.EditedAt)
        
        if let type: Int = dictionary.get(Keys.CandyType) {
            self.type <!= Int16(type)
        }
        
        let _: [Comment] = mappedEntries(dictionary.get(Keys.Comments), container: self)
        
        self.asset <!= self.asset?.editCandyAsset(dictionary, mediaType: mediaType)
        
        if wrap == nil {
            wrap <!= container as? Wrap ?? Wrap.entry(dictionary.get(Keys.UID.Wrap))
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
            wrap <!= container as? Wrap ?? Wrap.entry(dictionary.get(Keys.UID.Wrap))
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
        
        if let type: Int = dictionary.get(Keys.CommentType) {
            self.type <!= Int16(type)
        }
        
        if let urls = dictionary[Keys.MediaURLs] as? [String : String] {
            self.asset <!= self.asset?.edit(urls, metrics: AssetMetrics.mediaCommentMetrics, type: mediaType)
        } else {
            self.asset = nil
        }
        
        if self.candy == nil {
            if let candy = container as? Candy {
                self.candy = candy
            } else {
                self.candy <!= Candy.entry(dictionary.get(Keys.UID.Candy), locuid: dictionary.get(Keys.UID.CandyUpload))
            }
        }
    }
}
