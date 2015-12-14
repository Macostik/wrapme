//
//  EntryDesriptor.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import CoreData

class EntryDescriptor: NSObject {
    var name: String = ""
    var uid: String = ""
    var locuid: String?
    var container: String?
    var data: [String:AnyObject]?
    
    convenience init(name: String, uid: String) {
        self.init()
        self.name = name
        self.uid = uid
    }
    
    func entryExists() -> Bool {
        return EntryContext.sharedContext.hasEntry(name, uid: uid)
    }
    
    func belongsToEntry(entry: Entry) -> Bool {
        if let locuid = locuid {
            return uid == entry.uid || locuid == entry.locuid
        } else {
            return uid == entry.uid
        }
    }
}

extension EntryContext {
    
    func deleteEntry(entry: Entry) {
        cachedEntries.removeObjectForKey(entry.uid)
        deleteObject(entry)
        do {
            try save()
        } catch {
        }
    }
    
    func clear() {
        if let wraps = Wrap.entries() {
            for wrap in wraps {
                deleteObject(wrap)
            }
        }
        if let users = User.entries() {
            for user in users {
                deleteObject(user)
            }
        }
        do {
            try save()
        } catch {
        }
        cachedEntries.removeAllObjects()
    }
    
    func fetchEntries(descriptors: [EntryDescriptor]) {
        var uids = [String]()
        
        var descriptors = descriptors.filter { (descriptor) -> Bool in
            if cachedEntry(descriptor.uid) != nil {
                return false
            } else if let locuid = descriptor.locuid where cachedEntry(locuid) != nil {
                return false
            } else {
                uids.append(descriptor.uid)
                if let locuid = descriptor.locuid {
                    uids.append(locuid)
                }
                return true
            }
        }
        
        if descriptors.isEmpty {
            return
        }
        
        if let entries = Entry.fetch().query("uid IN %@ OR locuid IN %@", uids, uids).execute() as? [Entry] {
            for entry in entries {
                for (index, descriptor) in descriptors.enumerate() {
                    if descriptor.belongsToEntry(entry) {
                        entry.uid = descriptor.uid
                        cachedEntries.setObject(entry, forKey: descriptor.uid)
                        descriptors.removeAtIndex(index)
                        break
                    }
                }
            }
        }
        
        for descriptor in descriptors {
            if let entry = insertEntry(descriptor.name) {
                entry.uid = descriptor.uid
                entry.locuid = descriptor.locuid
                cachedEntries.setObject(entry, forKey: descriptor.uid)
            }
        }
    }
}

