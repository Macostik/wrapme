//
//  Entry+Base.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CoreData

extension Entry {
    
    class func entry() -> Self? {
        return entry(self)
    }
    
    class func entry<T>(type: T.Type) -> T? {
        if let entry = NSEntityDescription.insertNewObjectForEntityForName(entityName(), inManagedObjectContext: EntryContext.sharedContext) as? Entry {
            entry.identifier = NSString.GUID()
            entry.createdAt = NSDate.now()
            entry.updatedAt = entry.createdAt
            return entry as? T
        } else {
            return nil
        }
    }
    
    func markAsRead() {
        if valid && unread {
            unread = false
        }
    }
    
    func markAsUnread() {
        if valid && !unread {
            unread = true
        }
    }
    
    func remove() {
        let context = EntryContext.sharedContext
        context.assureSave {[weak self] () -> Void in
            if let entry = self {
                let container = entry.container
                entry.notifyOnDeleting()
                context.deleteEntry(entry)
                container?.notifyOnUpdate(.ContentDeleted)
            }
        }
    }
    
    func touch() {
        touch(NSDate.now())
    }
    
    func touch(date: NSDate) {
        if let container = container {
            container.touch(date)
        }
        updatedAt = date
    }
    
    func fetched() -> Bool {
        return true
    }
    
    func recursivelyFetched() -> Bool {
        var entry: Entry? = self
        while let _entry = entry {
            if !_entry.fetched() {
                return false
            }
            entry = _entry.container
        }
        return true
    }
}

extension User {
    
}

extension Device {
    
}

extension Contribution {
    
    class func contribution() -> Self? {
        return contribution(self)
    }
    
    class func contribution<T>(type: T.Type) -> T? {
        if let contributrion = entry() {
            contributrion.uploadIdentifier = contributrion.identifier
            contributrion.contributor = User.currentUser
            return contributrion as? T
        } else {
            return nil
        }
    }
}

extension Wrap {
    
    class func wrap() -> Self? {
        return wrap(self)
    }
    
    class func wrap<T>(type: T.Type) -> T? {
        if let wrap = contribution() {
            if let contributor = wrap.contributor {
                contributor.mutableWraps.addObject(wrap)
                wrap.contributors = NSSet(object: contributor)
            }
            return wrap as? T
        } else {
            return nil
        }
    }
    
    override func fetched() -> Bool {
        return !(name?.isEmpty ?? true) && contributor != nil
    }
}

extension Candy {
    
    class func candy(mediaType: MediaType) -> Self? {
        return candy(self, mediaType: mediaType)
    }
    
    class func candy<T>(type: T.Type, mediaType: MediaType) -> T? {
        if let candy = contribution() {
            candy.mediaType = mediaType
            return candy as? T
        } else {
            return nil
        }
    }
    
    override func fetched() -> Bool {
        return wrap != nil && !(picture?.original?.isEmpty ?? true)
    }
    
    func setEditedPicture(editedPicture: Asset) {
        switch status {
        case .Ready:
            picture = editedPicture
            break
        case .InProgress:
            break
        case .Finished:
            touch()
            editedAt = NSDate.now()
            editor = User.currentUser
            picture = editedPicture
            break
        }
    }
}

extension Message {
    
    override func fetched() -> Bool {
        return !(text?.isEmpty ?? true) && wrap != nil
    }
}

extension Comment {
    
    class func comment(text: String) -> Comment? {
        return comment(self, text: text)
    }
    
    class func comment<T>(type: T.Type, text: String) -> T? {
        if let comment = contribution() {
            comment.text = text
            return comment as? T
        } else {
            return nil
        }
    }
    
    override func fetched() -> Bool {
        return !(text?.isEmpty ?? true) && candy != nil
    }
}