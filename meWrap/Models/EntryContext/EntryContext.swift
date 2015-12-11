//
//  EntryContext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CoreData

private class EntryContextBlockWrapper {
    var block: Void -> Void
    required init(block: Void -> Void) {
        self.block = block
    }
}

class EntryContext: NSManagedObjectContext {
    
    var cachedEntries = NSMapTable.strongToWeakObjectsMapTable()
    
    private var assureSaveBlocks = [EntryContextBlockWrapper]()
    
    static var sharedContext: EntryContext = {
        let context = EntryContext(concurrencyType: .MainQueueConcurrencyType)
        
        let transformer = AssetTransformer()
        NSValueTransformer.setValueTransformer(transformer, forName: "pictureTransformer")
        NSValueTransformer.setValueTransformer(transformer, forName: "assetTransformer")
        guard let modelURL = NSBundle.mainBundle().URLForResource("CoreData", withExtension: "momd") else {
            return context
        }
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            return context
        }
        
        let manager = NSFileManager.defaultManager()
        
        var url: NSURL?
        
        let documentsURL = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last?.URLByAppendingPathComponent("CoreData.sqlite")
        
        #if TARGET_OS_WATCH
            url = documentsURL
        #else
            let sharedURL = manager.containerURLForSecurityApplicationGroupIdentifier("group.com.ravenpod.wraplive")?.URLByAppendingPathComponent("CoreData.sqlite")
            if sharedURL == nil {
                url = documentsURL
            } else {
                url = sharedURL
            }
        #endif
        
        guard let storeURL = url else {
            return context
        }
        
        let options = [NSMigratePersistentStoresAutomaticallyOption:true,NSInferMappingModelAutomaticallyOption:true,"journal_mode":"DELETE"]
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
        } catch {
            do {
                try manager.removeItemAtURL(storeURL)
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
            } catch {
            }
        }
        
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = NSOverwriteMergePolicy
        return context
    }()
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override init(concurrencyType ct: NSManagedObjectContextConcurrencyType) {
        super.init(concurrencyType: ct)
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "enqueueSave", name: "UIApplicationWillTerminateNotification", object: nil)
        center.addObserver(self, selector: "enqueueSave", name: "UIApplicationDidEnterBackgroundNotification", object: nil)
        center.addObserver(self, selector: "enqueueSave", name: "UIApplicationWillResignActiveNotification", object: nil)
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
            var request: NSFetchRequest!
            if let locuid = locuid {
                request = NSFetchRequest.fetch(name).query("uid == %@ OR locuid == %@", uid, locuid)
            } else {
                request = NSFetchRequest.fetch(name).query("uid == %@", uid)
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
        do {
            return try executeFetchRequest(request)
        } catch {
            return []
        }
    }
    
    func enqueueSave() {
        if hasChanges && persistentStoreCoordinator?.persistentStores.count > 0 {
            performBlockAndWait({[unowned self] () -> Void in
                do {
                    try self.save()
                } catch {
                }
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
            do {
                try self.executeRequest(NSAsynchronousFetchRequest(fetchRequest: request) { (result) -> Void in
                    completion(result.finalResult ?? [])
                    })
            } catch {
                completion([])
            }
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
        if var descriptors = sortDescriptors {
            descriptors.append(descriptor)
        } else {
            sortDescriptors = [descriptor]
        }
        return self
    }
    
    func group(properties: NSArray, fetch: NSArray) -> NSFetchRequest {
        guard let entity = entity else {
            return self
        }
        resultType = .DictionaryResultType
        let namedProerties = entity.propertiesByName
        var _propertiesToGroupBy = propertiesToGroupBy ?? [AnyObject]()
        for property in properties {
            if let propertyName = property as? String, let property = namedProerties[propertyName] {
                _propertiesToGroupBy.append(property)
            } else {
                _propertiesToGroupBy.append(property)
            }
        }
        propertiesToGroupBy = _propertiesToGroupBy
        
        var _propertiesToFetch = propertiesToFetch ?? [AnyObject]()
        for property in fetch {
            if let propertyName = property as? String, let property = namedProerties[propertyName] {
                _propertiesToFetch.append(property)
            } else {
                _propertiesToFetch.append(property)
            }
        }
        propertiesToFetch = _propertiesToFetch
        
        return self
    }
}
