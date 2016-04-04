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
        fetchCandies(wrap)
        request = PaginatedRequest.candies(wrap)
    }
    
    private var items: [HistoryItem] { return entries as! [HistoryItem] }
    
    private func fetchCandies(wrap: Wrap) {
        entries.removeAll()
        guard let candies = wrap.historyCandies where !candies.isEmpty else { return }
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
    
    override func _add(entry: ListEntry) -> Bool {
        guard let candy = entry as? Candy else { return false }
        return addCandy(candy).added
    }
    
    private func addCandy(candy: Candy) -> (item: HistoryItem, added: Bool) {
        let items = self.items
        if let item = items.last where item.date.isSameDay(candy.createdAt) {
            return (item, item.addCandy(candy))
        } else {
            for item in items where item.date.isSameDay(candy.createdAt) {
                return (item, item.addCandy(candy))
            }
        }
        let item = HistoryItem(candy: candy, history: self)
        entries.append(item)
        entries.sortInPlace({ $0.listSort($1) })
        return (item, true)
    }
    
    override func newerPaginationDate() -> NSDate? {
        return (entries.first as? HistoryItem)?.candies.last?.createdAt
    }
    
    override func olderPaginationDate() -> NSDate? {
        return nil
    }
    
    override func addEntries(entries: [ListEntry]) {
        guard let candies = entries as? [Candy] else { return }
        var added = false
        var items = Set<HistoryItem>()
        for candy in candies {
            let result = addCandy(candy)
            if result.added {
                items.insert(result.item)
                added = true
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
        items.all({ $0.sort() })
        didChange()
    }
    
    override func remove(entry: ListEntry) {
        guard let candy = entry as? Candy else { return }
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
    
    override func sort(entry: ListEntry) {
        guard let candy = entry as? Candy else { return }
        if let item = items[{ $0.candies.contains(candy) }] {
            item.sort()
        } else {
            addCandy(candy)
        }
    }
    
    override func add(entry: ListEntry) {
        guard let candy = entry as? Candy else { return }
        let result = addCandy(candy)
        result.item.sort()
        if result.added {
            didChange()
        }
    }
    
    func itemWithCandy(candy: Candy?) -> HistoryItem? {
        guard let candy = candy else { return nil }
        return items[{ $0.candies.contains(candy) }]
    }
}

extension History: EntryNotifying {
    
    func notifier(notifier: OrderedNotifier, shouldNotifyBeforeReceiver receiver: AnyObject) -> Bool {
        return true
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
    
    func listSort(entry: ListEntry) -> Bool {
        return listSortDate() > entry.listSortDate()
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
