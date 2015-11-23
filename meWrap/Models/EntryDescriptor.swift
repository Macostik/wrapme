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
}

extension EntryContext {
    func fetchEntries(descriptors: [String: EntryDescriptor]) {
        var uids = [String]()
        var locuids = [String]()
        
        var descriptors = descriptors
        let _descriptors = descriptors
        for (_, descriptor) in _descriptors {
            let uid = descriptor.uid
            if cachedEntry(uid) != nil {
                descriptors.removeValueForKey(uid)
            } else if let locuid = descriptor.locuid where cachedEntry(locuid) != nil {
                descriptors.removeValueForKey(locuid)
            } else {
                uids.append(descriptor.uid)
                if let locuid = descriptor.locuid {
                    locuids.append(locuid)
                }
            }
        }
        
        if descriptors.isEmpty {
            return
        }
        
        let entries = Entry.fetch().query("identifier IN %@ OR uploadIdentifier IN %@", uids, locuids).execute() as? [Entry]
        if let entries = entries {
            for entry in entries {
                
                var descriptor: EntryDescriptor?
                for (_, _descriptor) in descriptors {
                    if _descriptor.uid == entry.identifier || _descriptor.locuid == entry.uploadIdentifier {
                        descriptor = _descriptor
                        break
                    }
                }
                if let uid = descriptor?.uid {
                    descriptors.removeValueForKey(uid)
                    cachedEntries.setObject(entry, forKey: uid)
                } else if let uid = entry.identifier {
                    cachedEntries.setObject(entry, forKey: uid)
                }
            }
        }
        
        for (_, descriptor) in descriptors {
            if let entry = NSEntityDescription.insertNewObjectForEntityForName(descriptor.name, inManagedObjectContext: self) as? Entry {
                entry.identifier = descriptor.uid
                entry.uploadIdentifier = descriptor.locuid
                cachedEntries.setObject(entry, forKey: descriptor.uid)
            }
        }
    }
}
