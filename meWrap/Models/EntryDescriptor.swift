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
    var data: NSDictionary?
    
    convenience init(name: String, uid: String) {
        self.init()
        self.name = name
        self.uid = uid
    }
    
    func entryExists() -> Bool {
        return EntryContext.sharedContext.hasEntry(name, uid: uid)
    }
    
    func belongsToEntry(entry: Entry) -> Bool {
        return uid == entry.identifier || locuid == entry.uploadIdentifier
    }
}

extension EntryContext {
    
    func deleteEntry(entry: Entry) {
        cachedEntries.removeObjectForKey(entry.identifier)
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
        var locuids = [String]()
        
        var descriptors = descriptors.filter { (descriptor) -> Bool in
            if cachedEntry(descriptor.uid) != nil {
                return false
            } else if let locuid = descriptor.locuid where cachedEntry(locuid) != nil {
                return false
            } else {
                uids.append(descriptor.uid)
                if let locuid = descriptor.locuid {
                    locuids.append(locuid)
                }
                return true
            }
        }
        
        if descriptors.isEmpty {
            return
        }
        
        let entries = Entry.fetch().query("identifier IN %@ OR uploadIdentifier IN %@", uids, locuids).execute() as? [Entry]
        if let entries = entries {
            for entry in entries {
                for (index, descriptor) in descriptors.enumerate() {
                    if descriptor.belongsToEntry(entry) {
                        entry.identifier = descriptor.uid
                        cachedEntries.setObject(entry, forKey: descriptor.uid)
                        descriptors.removeAtIndex(index)
                        break
                    }
                }
            }
        }
        
        for descriptor in descriptors {
            if let entry = insertEntry(descriptor.name) {
                entry.identifier = descriptor.uid
                entry.uploadIdentifier = descriptor.locuid
                cachedEntries.setObject(entry, forKey: descriptor.uid)
            }
        }
    }
}

