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
    
    class func entry(uid: String?, locuid: String?) -> Self? {
        return entry(self, uid: uid, locuid: locuid)
    }
    
    class func entry<T>(type: T.Type, uid: String?, locuid: String?) -> T? {
        return EntryContext.sharedContext.entry(entityName(), uid: uid, locuid: locuid) as? T
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
                container?.notifyOnUpdate()
            }
        }
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
}

extension Message {
    
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
}