//
//  EntryNotifier.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/30/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

enum EntryUpdateEvent: Int {
    case Default, ContentAdded, ContentChanged, ContentDeleted, ContributorsChanged, PreferencesChanged, LiveBroadcastsChanged, NumberOfUnreadMessagesChanged, InboxChanged, UserStatus
}

protocol EntryNotifying: class {
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool
    func notifier(notifier: EntryNotifier, shouldNotifyOnContainer container: Entry) -> Bool
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry)
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent)
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry)
    func notifier(notifier: EntryNotifier, willDeleteContainer container: Entry)
}

extension EntryNotifying {
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool { return true }
    func notifier(notifier: EntryNotifier, shouldNotifyOnContainer container: Entry) -> Bool { return true }
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {}
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {}
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {}
    func notifier(notifier: EntryNotifier, willDeleteContainer container: Entry) {}
}

struct EntryNotifyingWrapper {
    weak var receiver: EntryNotifying?
}

final class EntryNotifier {
    
    internal var receivers = [EntryNotifyingWrapper]()
    
    func addReceiver(receiver: EntryNotifying) {
        self.receivers = self.receivers.filter { $0.receiver != nil }
        receivers.append(EntryNotifyingWrapper(receiver: receiver))
    }
    
    func insertReceiver(receiver: EntryNotifying) {
        self.receivers = self.receivers.filter { $0.receiver != nil }
        receivers.insert(EntryNotifyingWrapper(receiver: receiver), atIndex: 0)
    }
    
    func removeReceiver(receiver: EntryNotifying) {
        if let index = receivers.indexOf({ $0.receiver === receiver }) {
            receivers.removeAtIndex(index)
        }
    }
    
    func notify(@noescape enumerator: (receiver: EntryNotifying) -> Void) {
        for wrapper in receivers {
            if let receiver = wrapper.receiver {
                enumerator(receiver: receiver)
            }
        }
    }
    
    private static var notifiers = [String : EntryNotifier]()
    
    static func notifierForName(name: String) -> EntryNotifier {
        if let notifier = EntryNotifier.notifiers[name] {
            return notifier
        } else {
            let notifier = EntryNotifier()
            EntryNotifier.notifiers[name] = notifier
            return notifier
        }
    }
    
    func notifyOnEntry(entry: Entry, @noescape block: EntryNotifying -> Void) {
        notify { (receiver) -> Void in
            if receiver.notifier(self, shouldNotifyOnEntry: entry) {
                block(receiver)
            }
        }
    }
    
    func notifyOnAddition(entry: Entry) {
        notifyOnEntry(entry) { $0.notifier(self, didAddEntry: entry) }
    }
    
    func notifyOnUpdate(entry: Entry, event: EntryUpdateEvent) {
        notifyOnEntry(entry) { $0.notifier(self, didUpdateEntry: entry, event: event) }
    }
    
    func notifyOnDeleting(entry: Entry) {
        if let contentTypes = entry.dynamicType.contentTypes() {
            for type in contentTypes {
                type.notifier().notifyOnDeletingContainer(entry)
            }
        }
        notifyOnEntry(entry) { $0.notifier(self, willDeleteEntry: entry) }
    }
    
    func notifyOnDeletingContainer(container: Entry) {
        notify { (receiver) -> Void in
            if receiver.notifier(self, shouldNotifyOnContainer: container) {
                receiver.notifier(self, willDeleteContainer: container)
            }
        }
    }
}

final class EntryNotifyReceiver<T: Entry>: EntryNotifying {
    var entry: (Void -> T?)?
    var container: (Void -> Entry?)?
    var shouldNotify: (T -> Bool)?
    var didAdd: (T -> Void)?
    var didUpdate: ((T, EntryUpdateEvent) -> Void)?
    var willDelete: (T -> Void)?
    var willDeleteContainer: (Entry -> Void)?
    
    init() {
        T.notifier().addReceiver(self)
    }
    
    func setup( @noescape block: EntryNotifyReceiver -> Void) -> Self {
        block(self)
        return self
    }
    
    // MARK: - EntryNotifying
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        if let shouldNotify = shouldNotify {
            return shouldNotify(entry as! T)
        } else if let _container = self.container?() where _container != entry.container {
            return false
        } else if let _entry = self.entry?() {
            return _entry == entry
        } else {
            return true
        }
    }
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        didAdd?(entry as! T)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        didUpdate?(entry as! T, event)
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        willDelete?(entry as! T)
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
