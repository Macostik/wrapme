//
//  EntryNotifier.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/30/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc enum EntryUpdateEvent: Int {
    case Default, ContentAdded, ContentChanged, ContentDeleted, ContributorsChanged, PreferencesChanged, LiveBroadcastsChanged, NumberOfUnreadMessagesChanged, InboxChanged
}

@objc protocol EntryNotifying: OrderedNotifierReceiver {
    optional func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool
    
    optional func notifier(notifier: EntryNotifier, shouldNotifyOnContainer container: Entry) -> Bool
    
    optional func notifier(notifier: EntryNotifier, didAddEntry entry: Entry)
    
    optional func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent)
    
    optional func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry)
    
    optional func notifier(notifier: EntryNotifier, willDeleteContainer container: Entry)
}

class EntryNotifier: OrderedNotifier {
    
    let name: String
    
    required init(name: String) {
        self.name = name
        super.init()
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
    
    func notifyOnEntry(entry: Entry, @noescape block: AnyObject -> Void) {
        notify { (receiver) -> Void in
            if receiver.notifier?(self, shouldNotifyOnEntry: entry) ?? true {
                block(receiver)
            }
        }
    }
    
    func notifyOnAddition(entry: Entry) {
        notifyOnEntry(entry) { $0.notifier?(self, didAddEntry: entry) }
    }
    
    func notifyOnUpdate(entry: Entry, event: EntryUpdateEvent) {
        notifyOnEntry(entry) { $0.notifier?(self, didUpdateEntry: entry, event: event) }
    }
    
    func notifyOnDeleting(entry: Entry) {
        if let contentTypes = entry.dynamicType.contentTypes() {
            for type in contentTypes {
                type.notifier().notifyOnDeletingContainer(entry)
            }
        }
        notifyOnEntry(entry) { $0.notifier?(self, willDeleteEntry: entry) }
    }
    
    func notifyOnDeletingContainer(container: Entry) {
        notify { (receiver) -> Void in
            if receiver.notifier?(self, shouldNotifyOnContainer: container) ?? true {
                receiver.notifier?(self, willDeleteContainer: container)
            }
        }
    }
}

class EntryNotifyReceiver: NSObject, EntryNotifying {
    var entry: (Void -> Entry?)?
    var container: (Void -> Entry?)?
    var shouldNotify: (Entry -> Bool)?
    var didAdd: (Entry -> Void)?
    var didUpdate: ((Entry, EntryUpdateEvent) -> Void)?
    var willDelete: (Entry -> Void)?
    var willDeleteContainer: (Entry -> Void)?
    
    func setup( @noescape block: EntryNotifyReceiver -> Void) -> Self {
        block(self)
        return self
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
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        didUpdate?(entry, event)
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
    
    class func notifyReceiver() -> EntryNotifyReceiver {
        let receiver = EntryNotifyReceiver()
        notifier().addReceiver(receiver)
        return receiver
    }
    
    func notifyOnAddition() {
        self.dynamicType.notifier().notifyOnAddition(self)
        touchContainer()
    }
    
    func notifyOnUpdate(event: EntryUpdateEvent) {
        self.dynamicType.notifier().notifyOnUpdate(self, event: event)
        touchContainer()
    }
    
    func notifyOnDeleting() {
        self.dynamicType.notifier().notifyOnDeleting(self)
    }
    
    func touchContainer() {
        guard let container = container else { return }
        if updatedAt.later(container.updatedAt) {
            container.updatedAt = updatedAt
        } else if createdAt.later(container.updatedAt) {
            container.updatedAt = createdAt
        }
        container.notifyOnUpdate(.ContentChanged)
    }
}
