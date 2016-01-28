//
//  EntryContext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CoreData

private struct EntryContextBlockWrapper {
    var block: Void -> Void
}

class EntryContext: NSManagedObjectContext {
    
    var cachedEntries = NSMapTable.strongToWeakObjectsMapTable()
    
    private var assureSaveBlocks = [EntryContextBlockWrapper]()
    
    static var sharedContext: EntryContext = {
        let context = EntryContext(concurrencyType: .MainQueueConcurrencyType)
        context.retainsRegisteredObjects = true
        let transformer = AssetTransformer()
        NSValueTransformer.setValueTransformer(transformer, forName: "pictureTransformer")
        NSValueTransformer.setValueTransformer(transformer, forName: "assetTransformer")
        guard let model = EntryContext.createModel() else { return context }
        context.persistentStoreCoordinator = EntryContext.createCoordinator(model)
        context.mergePolicy = NSOverwriteMergePolicy
        return context
    }()
    
    private class func createCoordinator(model: NSManagedObjectModel) -> NSPersistentStoreCoordinator {
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        guard let storeURL = storeURL()?.URLByAppendingPathComponent("CoreData.sqlite") else { return coordinator }
        
        let options = [NSMigratePersistentStoresAutomaticallyOption:true,NSInferMappingModelAutomaticallyOption:true,"journal_mode":"DELETE"]
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
        } catch {
            _ = try? NSFileManager.defaultManager().removeItemAtURL(storeURL)
            _ = try? coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
        }
        
        return coordinator
    }
    
    private class func storeURL() -> NSURL? {
        let manager = NSFileManager.defaultManager()
        if let url = manager.containerURLForSecurityApplicationGroupIdentifier(Constants.groupIdentifier) {
            return url
        } else {
            return manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last
        }
    }
    
    private class func createModel() -> NSManagedObjectModel? {
        if let modelURL = NSBundle.mainBundle().URLForResource("CoreData", withExtension: "momd") {
            return NSManagedObjectModel(contentsOfURL: modelURL)
        } else {
            return nil
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override init(concurrencyType ct: NSManagedObjectContextConcurrencyType) {
        super.init(concurrencyType: ct)
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "enqueueSave", name: UIApplicationWillTerminateNotification, object: nil)
        center.addObserver(self, selector: "enqueueSave", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: "enqueueSave", name: UIApplicationWillResignActiveNotification, object: nil)
        center.addObserver(self, selector: "enqueueSave", name: NSManagedObjectContextObjectsDidChangeNotification, object: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cachedEntry(uid: String) -> Entry? {
        return cachedEntries.objectForKey(uid) as? Entry
    }
    
    func cacheEntry(entry: Entry) {
        cachedEntries.setObject(entry, forKey: entry.uid)
    }
    
    func uncacheEntry(entry: Entry) {
        cachedEntries.removeObjectForKey(entry.uid)
    }
    
    func insertEntry(name: String) -> Entry? {
        return NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self) as? Entry
    }
    
    func entry(name: String, uid: String?) -> Entry? {
        return entry(name, uid: uid, locuid: nil)
    }
    
    func entry(name: String, uid: String?, locuid: String?) -> Entry? {
        return entry(name, uid: uid, locuid: locuid, allowInsert: true)
    }
    
    func entry(name: String, uid: String?, locuid: String?, allowInsert: Bool) -> Entry? {
        guard let uid = uid else {
            return nil
        }
        if let entry = cachedEntry(uid) {
            return entry
        } else {
            var request = NSFetchRequest.fetch(name)
            if let locuid = locuid {
                request = request.query("uid == %@ OR locuid == %@", uid, locuid)
            } else {
                request = request.query("uid == %@", uid)
            }
            if let entry = request.execute().last as? Entry {
                return entry
            } else if allowInsert {
                if let entry = insertEntry(name) {
                    entry.uid = uid
                    return entry
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    func entry<T: Entry>(type: T.Type, uid: String?, locuid: String?, allowInsert: Bool) -> T? {
        return entry(type.entityName(), uid: uid, locuid: locuid, allowInsert: allowInsert) as? T
    }
    
    func entry<T: Entry>(type: T.Type, name: String, uid: String?, locuid: String?, allowInsert: Bool) -> T? {
        return entry(name, uid: uid, locuid: locuid, allowInsert: allowInsert) as? T
    }
    
    func hasEntry(name: String, uid: String?) -> Bool {
        guard let uid = uid else {
            return false
        }
        if cachedEntries.objectForKey(uid) != nil {
            return true
        }
        return NSFetchRequest.fetch(name).query("uid == %@", uid).count() > 0
    }
    
    func execute(request: NSFetchRequest) -> [AnyObject] {
        return (try? executeFetchRequest(request)) ?? []
    }
    
    func enqueueSave() {
        if hasChanges && persistentStoreCoordinator?.persistentStores.count > 0 {
            performBlockAndWait({[unowned self] () -> Void in
                _ = try? self.save()
            })
            if assureSaveBlocks.count > 0 {
                let blocks = assureSaveBlocks
                for wrapper in blocks {
                    wrapper.block()
                }
                assureSaveBlocks.removeAll()
            }
        }
    }
    
    func assureSave(block: Void -> Void) {
        if hasChanges {
            assureSaveBlocks.append(EntryContextBlockWrapper(block: block))
        } else {
            block()
        }
    }
    
    func execute(request: NSFetchRequest, completion: [AnyObject] -> Void) {
        performBlock { () -> Void in
            _ = try? self.executeRequest(NSAsynchronousFetchRequest(fetchRequest: request) { (result) -> Void in
                completion(result.finalResult ?? [])
                })
        }
    }
}

extension NSFetchRequest {
    
    class func fetch(name: String) -> NSFetchRequest {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName(name, inManagedObjectContext: EntryContext.sharedContext)
        return request
    }
    
    func queryString(format: String) -> NSFetchRequest {
        predicate = NSPredicate(format: format)
        return self
    }
    
    private func query(format: String, arguments: CVaListPointer) -> NSFetchRequest {
        predicate = NSPredicate(format: format, arguments: arguments)
        return self
    }
    
    func query(format: String, _ args: CVarArgType...) -> NSFetchRequest {
        return query(format, arguments: getVaList(args))
    }
    
    func execute() -> [AnyObject] {
        return EntryContext.sharedContext.execute(self)
    }
    
    func execute(completion: [AnyObject] -> Void) {
        EntryContext.sharedContext.execute(self, completion: completion)
    }
    
    func count() -> Int {
        return EntryContext.sharedContext.countForFetchRequest(self, error: nil)
    }
    
    func limit(limit: Int) -> NSFetchRequest {
        fetchLimit = limit
        return self
    }
    
    func sort(key: String) -> NSFetchRequest {
        return sort(key, asc: false)
    }
    
    func sort(key: String, asc: Bool) -> NSFetchRequest {
        let descriptor = NSSortDescriptor(key: key, ascending: asc)
        var descriptors: [NSSortDescriptor] = sortDescriptors ?? []
        descriptors.append(descriptor)
        sortDescriptors = descriptors
        return self
    }
}
