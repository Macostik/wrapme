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
    
    override var description: String { return "\(name): \(uid), upload_uid = \(locuid ?? "")" }
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
}

extension Contribution {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(descriptors, inDictionary: dictionary?["contributor"] as? [String:AnyObject])
    }
}

extension Wrap {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(descriptors, inArray: dictionary?["contributors"] as? [[String:AnyObject]])
        User.prefetchDescriptors(descriptors, inDictionary: dictionary?["creator"] as? [String:AnyObject])
        Candy.prefetchDescriptors(descriptors, inArray: dictionary?["candies"] as? [[String:AnyObject]])
    }
}

extension Candy {
    
    override class func prefetchDescriptors(descriptors: NSMutableDictionary, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(descriptors, inDictionary: dictionary?["editor"] as? [String:AnyObject])
        Comment.prefetchDescriptors(descriptors, inArray: dictionary?["comments"] as? [[String:AnyObject]])
    }
}

extension EntryContext {
    
    func deleteEntry(entry: Entry) {
        cachedEntries.removeObjectForKey(entry.uid)
        deleteObject(entry)
        _ = try? save()
    }
    
    func clear() {
        for wrap in FetchRequest<Wrap>().execute() {
            deleteObject(wrap)
        }
        for user in FetchRequest<User>().execute() {
            deleteObject(user)
        }
        _ = try? save()
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
        
        for entry in FetchRequest<Entry>(query: "uid IN %@ OR locuid IN %@", uids, uids).execute() {
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

