//
//  EntryNotifier.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/30/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol EntryNotifying {
    optional func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool
    
    optional func notifier(notifier: EntryNotifier, shouldNotifyOnContainer container: Entry) -> Bool
    
    optional func notifier(notifier: EntryNotifier, didAddEntry entry: Entry)
    
    optional func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry)
    
    optional func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry)
    
    optional func notifier(notifier: EntryNotifier, willDeleteContainer container: Entry)
}

class EntryNotifier: WLBroadcaster {
    
    let name: String
    
    private var selectEntryBlock: WLBroadcastSelectReceiver!
    
    private var selectContainerBlock: WLBroadcastSelectReceiver!
    
    required init(name: String) {
        self.name = name
        super.init()
        selectEntryBlock = { (receiver, entry) -> Bool in
            guard let receiver = receiver as? EntryNotifying else {
                return false
            }
            guard let entry = entry as? Entry else {
                return false
            }
            return receiver.notifier?(self, shouldNotifyOnEntry: entry) ?? true
        }
        selectContainerBlock = { (receiver, container) -> Bool in
            guard let receiver = receiver as? EntryNotifying else {
                return false
            }
            guard let container = container as? Entry else {
                return false
            }
            return receiver.notifier?(self, shouldNotifyOnContainer: container) ?? true
        }
    }
    
    private static var notifiers = [String : EntryNotifier]()
    
    class func notifierForName(name: String) -> EntryNotifier {
        if let notifier = EntryNotifier.notifiers[name] {
            return notifier
        } else {
            let notifier = EntryNotifier(name: name)
            EntryNotifier.notifiers[name] = notifier
            return notifier
        }
    }
    
    func notifyOnAddition(entry: Entry) {
        broadcast("notifier:didAddEntry:", object: entry, select: selectEntryBlock)
    }
    
    func notifyOnUpdate(entry: Entry) {
        broadcast("notifier:didUpdateEntry:", object: entry, select: selectEntryBlock)
    }
    
    func notifyOnDeleting(entry: Entry) {
        if let contentEntityNames = entry.dynamicType.contentEntityNames() {
            for entityName in contentEntityNames {
                EntryNotifier.notifierForName(entityName).notifyOnDeletingContainer(entry)
            }
        }
        broadcast("notifier:willDeleteEntry:", object: entry, select: selectEntryBlock)
    }
    
    func notifyOnDeletingContainer(container: Entry) {
        broadcast("notifier:willDeleteContainer:", object: container, select: selectContainerBlock)
    }
}

class EntryNotifyReceiver: NSObject, EntryNotifying {
    var entry: (Void -> Entry?)?
    var container: (Void -> Entry?)?
    var shouldNotify: (Entry -> Bool)?
    var didAdd: (Entry -> Void)?
    var didUpdate: (Entry -> Void)?
    var willDelete: (Entry -> Void)?
    var willDeleteContainer: (Entry -> Void)?
    
    func setup(block: EntryNotifyReceiver -> Void) {
        block(self)
    }
    
    // MARK: - EntryNotifying
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        if let shouldNotify = shouldNotify {
            return shouldNotify(entry)
        } else if let _container = self.container?() where _container != entry.container {
            return false
        } else if let _entry = self.entry?() {
            return _entry == entry
        } else {
            return true
        }
    }
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        didAdd?(entry)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry) {
        didUpdate?(entry)
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        willDelete?(entry)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnContainer container: Entry) -> Bool {
        if let _container = self.container?() where _container != container {
            return false
        } else {
            return true
        }
    }
    
    func notifier(notifier: EntryNotifier, willDeleteContainer container: Entry) {
        willDeleteContainer?(container)
    }
}

extension Entry {
    
    class func notifier() -> EntryNotifier {
        return EntryNotifier.notifierForName(entityName())
    }
    
    class func notifyReceiver(owner: AnyObject) -> EntryNotifyReceiver {
        let receiver = EntryNotifyReceiver()
        objc_setAssociatedObject(owner, "\(entityName())_EntryNotifyReceiver", receiver, .OBJC_ASSOCIATION_RETAIN)
        notifier().addReceiver(receiver)
        return receiver
    }
    
    func notifyOnAddition() {
        self.dynamicType.notifier().notifyOnAddition(self)
        touchContainer()
    }
    
    func notifyOnUpdate() {
        self.dynamicType.notifier().notifyOnUpdate(self)
        touchContainer()
    }
    
    func notifyOnDeleting() {
        self.dynamicType.notifier().notifyOnDeleting(self)
    }
    
    func touchContainer() {
        
        guard let container = container else {
            return
        }
        if container.updatedAt.compare(updatedAt) == .OrderedAscending {
            container.updatedAt = updatedAt
            container.notifyOnUpdate()
        }
    }
}
