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
        return "\(self.dynamicType.entityName()): \(identifier ?? "no_uid")"
    }
    
    func compare(entry: Entry) -> NSComparisonResult {
        return updatedAt.compare(entry.updatedAt)
    }
    
    class func entry(uid: String?) -> Self? {
        return entry(uid, locuid: nil)
    }
    
    class func entry(uid: String?, locuid: String?) -> Self? {
        return entry(self, uid: uid, locuid: locuid, allowInsert: true)
    }
    
    class func entry(uid: String?, allowInsert: Bool) -> Self? {
        return entry(self, uid: uid, locuid: nil, allowInsert: allowInsert)
    }
    
    class func entry(uid: String?, locuid: String?, allowInsert: Bool) -> Self? {
        return entry(self, uid: uid, locuid: locuid, allowInsert: allowInsert)
    }
    
    class func entry<T>(type: T.Type, uid: String?, locuid: String?, allowInsert: Bool) -> T? {
        return EntryContext.sharedContext.entry(entityName(), uid: uid, locuid: locuid, allowInsert: allowInsert) as? T
    }
    
    class func entryExists(uid: String?) -> Bool {
        return EntryContext.sharedContext.hasEntry(entityName(), uid: uid)
    }
    
    class func entries() -> [Entry]? {
        return fetch().execute() as? [Entry]
    }
    
    class func fetch() -> NSFetchRequest {
        return NSFetchRequest.fetch(entityName())
    }
    
    class func deserializeReference(reference: [String : String]) -> Self? {
        return deserializeReference(self, reference: reference)
    }
    
    class func deserializeReference<T>(type: T.Type, reference: [String : String]) -> T? {
        guard let name = reference["name"], let uid = reference["identifier"] else {
            return nil
        }
        return EntryContext.sharedContext.entry(name, uid: uid, locuid: nil, allowInsert: false) as? T
    }
    
    func serializeReference() -> [String : String]? {
        guard let identifier = identifier else {
            return nil
        }
        return ["name":self.dynamicType.entityName(), "identifier":identifier];
    }
    
    var valid: Bool {
        return managedObjectContext != nil && !self.deleted && (container?.valid ?? true)
    }
    
    var container: Entry?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        EntryContext.sharedContext.cacheEntry(self)
        if picture == nil {
            picture = Asset()
        }
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
