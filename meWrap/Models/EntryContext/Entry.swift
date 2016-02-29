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

    class func entityName() -> String { return "Entry" }
    
    class func containerType() -> Entry.Type? { return nil }
    
    class func contentTypes() -> [Entry.Type]? { return nil }
    
    override var description: String { return "\(self.dynamicType.entityName()): \(uid), upload_uid = \(locuid ?? "")" }
    
    func compare(entry: Entry) -> NSComparisonResult { return updatedAt.compare(entry.updatedAt) }
    
    class func entry(uid: String?, locuid: String? = nil, allowInsert: Bool = true) -> Self? {
        return EntryContext.sharedContext.entry(self, uid: uid, locuid: locuid, allowInsert: allowInsert)
    }
    
    class func entryExists(uid: String?) -> Bool {
        return EntryContext.sharedContext.hasEntry(entityName(), uid: uid)
    }
    
    class func deserializeReference(reference: [String : String]) -> Self? {
        guard let name = reference["name"], let uid = reference["uid"] else {
            return nil
        }
        return EntryContext.sharedContext.entry(self, name: name, uid: uid, allowInsert: false)
    }
    
    func serializeReference() -> [String : String] {
        return ["name":self.dynamicType.entityName(), "uid":uid];
    }
    
    var valid: Bool { return managedObjectContext != nil && !self.deleted && (container?.valid ?? true) }
    
    func validEntry() -> Self? { return valid ? self : nil }
    
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
