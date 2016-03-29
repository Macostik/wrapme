//
//  EntryDesriptor.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import CoreData

func ==(lhs: EntryDescriptor, rhs: EntryDescriptor) -> Bool {
    return lhs.uid == rhs.uid
}

struct EntryDescriptor: Hashable {
    var name: String
    var uid: String
    var locuid: String?
    var container: String?
    var data: [String:AnyObject]?
    
    init(name: String, uid: String, locuid: String?) {
        self.name = name
        self.uid = uid
        self.locuid = locuid
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
    
    var description: String { return "\(name): \(uid), upload_uid = \(locuid ?? "")" }
    
    var hashValue: Int { return uid.hashValue }
}

extension Entry {
    
    class func prefetchArray(array: [[String : AnyObject]]) -> [[String : AnyObject]] {
        var descriptors = Set<EntryDescriptor>()
        prefetchDescriptors(&descriptors, inArray:array)
        EntryContext.sharedContext.fetchEntries(descriptors)
        return array
    }
    
    class func prefetchDictionary(dictionary: [String : AnyObject]) -> [String : AnyObject] {
        var descriptors = Set<EntryDescriptor>()
        prefetchDescriptors(&descriptors, inDictionary: dictionary)
        EntryContext.sharedContext.fetchEntries(descriptors)
        return dictionary
    }
    
    class func prefetchDescriptors(inout descriptors: Set<EntryDescriptor>, inArray array: [[String : AnyObject]]?) {
        guard let array = array else { return }
        for dictionary in array {
            prefetchDescriptors(&descriptors, inDictionary: dictionary)
        }
    }
}

extension EntryContext {
    
    func fetchEntries(descriptors: Set<EntryDescriptor>) {
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
        
        let fetchedEntries = FetchRequest<Entry>(query: "uid IN %@ OR locuid IN %@", uids, uids).execute()
        
        for entry in fetchedEntries {
            for (index, descriptor) in descriptors.enumerate() {
                if descriptor.belongsToEntry(entry) {
                    entry.uid = descriptor.uid
                    cachedEntries.setObject(entry, forKey: descriptor.uid)
                    descriptors.removeAtIndex(index)
                    break
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

