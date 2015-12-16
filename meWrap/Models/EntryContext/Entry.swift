//
//  Entry.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(Entry)
class Entry: NSManagedObject {

    class func entityName() -> String {
        return "Entry"
    }
    
    class func containerEntityName() -> String? {
        return nil
    }
    
    class func contentEntityNames() -> Set<String>? {
        return nil
    }
    
    override var description: String {
        return "\(self.dynamicType.entityName()): \(uid)"
    }
    
    func compare(entry: Entry) -> NSComparisonResult {
        return updatedAt.compare(entry.updatedAt)
    }
    
    class func entry(uid: String?) -> Self? {
        return entry(uid, locuid: nil)
    }
    
    class func entry(uid: String?, locuid: String?) -> Self? {
        return entry(uid, locuid: locuid, allowInsert: true)
    }
    
    class func entry(uid: String?, allowInsert: Bool) -> Self? {
        return entry(uid, locuid: nil, allowInsert: allowInsert)
    }
    
    class func entry(uid: String?, locuid: String?, allowInsert: Bool) -> Self? {
        return EntryContext.sharedContext.entry(self, uid: uid, locuid: locuid, allowInsert: allowInsert)
    }
    
    class func entryExists(uid: String?) -> Bool {
        return EntryContext.sharedContext.hasEntry(entityName(), uid: uid)
    }
    
    class func entries() -> [Entry] {
        return (fetch().execute() as? [Entry]) ?? []
    }
    
    class func fetch() -> NSFetchRequest {
        return NSFetchRequest.fetch(entityName())
    }
    
    class func deserializeReference(reference: [String : String]) -> Self? {
        guard let name = reference["name"], let uid = reference["uid"] else {
            return nil
        }
        return EntryContext.sharedContext.entry(self, name: name, uid: uid, locuid: nil, allowInsert: false)
    }
    
    func serializeReference() -> [String : String] {
        return ["name":self.dynamicType.entityName(), "uid":uid];
    }
    
    var valid: Bool {
        return managedObjectContext != nil && !self.deleted && (container?.valid ?? true)
    }
    
    func validEntry() -> Self? {
        return valid ? self : nil
    }
    
    var container: Entry?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        EntryContext.sharedContext.cacheEntry(self)
        createdAt = NSDate.now()
    }
    
    override func awakeFromFetch() {
        super.awakeFromFetch()
        EntryContext.sharedContext.cacheEntry(self)
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        EntryContext.sharedContext.uncacheEntry(self)
    }
}
