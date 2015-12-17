//
//  History.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/4/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class History: PaginatedList {
    
    weak var wrap: Wrap?
    
    required init(wrap: Wrap) {
        super.init()
        Candy.notifier().addReceiver(self)
        self.wrap = wrap
        fetchCandies()
        request = PaginatedRequest.candies(wrap)
    }
    
    private func fetchCandies() {
        entries.removeAll()
        guard let candies = wrap?.historyCandies where !candies.isEmpty else {
            return
        }
        var _candy: Candy?
        var item: HistoryItem!
        for candy in candies {
            if let _candy = _candy {
                if _candy.createdAt.isSameDay(candy.createdAt) {
                    item.candies.append(candy)
                } else {
                    entries.insert(item, atIndex: 0)
                    item = HistoryItem(candy: candy, history: self)
                }
            } else {
                item = HistoryItem(candy: candy, history: self)
            }
            _candy = candy
        }
        entries.insert(item, atIndex: 0)
    }
    
    private func addCandy(candy: Candy) -> (item: HistoryItem, added: Bool) {
        if let items = entries as? [HistoryItem] {
            if let item = items.last where item.date.isSameDay(candy.createdAt) {
                return (item, item.addCandy(candy))
            } else {
                for item in items where item.date.isSameDay(candy.createdAt) {
                    return (item, item.addCandy(candy))
                }
            }
        }
        let item = HistoryItem(candy: candy, history: self)
        entries.append(item)
        entries.sortInPlace({ $0.listSortDate() > $1.listSortDate() })
        return (item, true)
    }
    
    override func newerPaginationDate() -> NSDate? {
        return (entries.first as? HistoryItem)?.candies.first?.createdAt
    }
    
    override func olderPaginationDate() -> NSDate? {
        return nil
    }
    
    override func addEntries(entries: [ListEntry]) {
        
        var added = false
        var items = Set<HistoryItem>()
        if let candies = entries as? [Candy] {
            for candy in candies {
                let result = addCandy(candy)
                if result.added {
                    items.insert(result.item)
                    added = true
                }
            }
        }
        for item in items {
            item.sort()
        }
        if added {
            didChange()
        }
    }
    
    override func sort() {
        if let items = entries as? [HistoryItem] {
            for item in items {
                item.sort()
            }
        }
        didChange()
    }
    
    override func remove(entry: ListEntry) {
        if let candy = entry as? Candy, let items = entries as? [HistoryItem] {
            for (itemIndex, item) in items.enumerate() {
                if let index = item.candies.indexOf(candy) {
                    item.candies.removeAtIndex(index)
                    if item.candies.count == 0 {
                        entries.removeAtIndex(itemIndex)
                    }
                    didChange()
                    break
                }
            }
        }
    }
    
    override func add(entry: ListEntry) {
        if let candy = entry as? Candy {
            let result = addCandy(candy)
            result.item.sort()
            if result.added {
                didChange()
            }
        }
    }
    
    func itemWithCandy(candy: Candy?) -> HistoryItem? {
        guard let candy = candy else { return nil }
        if let items = entries as? [HistoryItem] {
            for item in items where item.candies.contains(candy) {
                return item
            }
        }
        return nil
    }
}

extension History: EntryNotifying {
    
    func broadcasterOrderPriority(broadcaster: WLBroadcaster!) -> Int {
        return WLBroadcastReceiverOrderPriorityPrimary
    }
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        add(entry)
        if let contributor = (entry as? Candy)?.contributor where contributor.current {
            didChange()
        }
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        remove(entry)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        sort(entry)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry.container
    }
}

class HistoryItem: NSObject, ListEntry {
    
    unowned var history: History
    
    var offset = CGPoint.zero
    var scrollToMaximumOffset = false
    
    var candies = [Candy]()
    var date: NSDate
    
    init(candy: Candy, history: History) {
        self.history = history
        date = candy.createdAt
        candies.append(candy)
    }
    
    func sort() {
        candies.sortInPlace({ $0.createdAt < $1.createdAt })
    }
    
    func listSortDate() -> NSDate {
        return date
    }
    func listEntryEqual(entry: ListEntry) -> Bool {
        return self == (entry as? HistoryItem)
    }
    
    func addCandy(candy: Candy) -> Bool {
        if !candies.contains(candy) {
            candies.append(candy)
            return true
        } else {
            return false
        }
    }
}
