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
        if let candies = wrap?.historyCandies {
            var _candy: Candy?
            var item: HistoryItem!
            for candy in candies {
                if let _candy = _candy {
                    if _candy.createdAt.isSameDay(candy.createdAt) {
                        item.candies.append(candy)
                    } else {
                        entries.append(item)
                        item = HistoryItem(candy: candy)
                    }
                } else {
                    item = HistoryItem(candy: candy)
                }
                _candy = candy
            }
            entries.append(item)
        }
    }
    
    private func addCandy(candy: Candy) -> (item: HistoryItem, added: Bool) {
        if let items = entries as? [HistoryItem] {
            for item in items {
                if item.date.isSameDay(candy.createdAt) {
                    if !item.candies.contains(candy) {
                        item.candies.append(candy)
                        return (item, true)
                    } else {
                        return (item, false)
                    }
                }
            }
        }
        let item = HistoryItem(candy: candy)
        entries.append(item)
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
    var offset = CGPoint.zero
    var candies = [Candy]()
    var date: NSDate
    convenience init(candy: Candy) {
        self.init(date: candy.createdAt)
        candies.append(candy)
    }
    
    init(date: NSDate) {
        self.date = date
    }
    
    func sort() {
        candies.sortInPlace({ $0.createdAt > $1.createdAt })
    }
    
    func listSortDate() -> NSDate {
        return date
    }
}
