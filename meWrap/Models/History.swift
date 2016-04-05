//
//  History.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/4/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class History: PaginatedList<HistoryItem> {
    
    weak var wrap: Wrap?
    
    private var historyCandies: PaginatedList<Candy>
    
    required init(wrap: Wrap) {
        super.init()
        Candy.notifier().addReceiver(self)
        self.wrap = wrap
        fetchCandies(wrap)
        historyCandies = PaginatedList<Candy>(entries: wrap.historyCandies ?? [], request: API.candies(wrap))
    }
    
    override var completed: Bool {
        get {
            return historyCandies.completed
        }
        set {
            historyCandies.completed = newValue
        }
    }
    
    func send(type: PaginatedRequestType, success: ([Candy]? -> ())?, failure: FailureBlock?) {
        historyCandies.send(type, success: { [weak self] candies in
            self?.addCandies(candies)
            success?(candies)
            }, failure: failure)
    }
    
    private func fetchCandies(wrap: Wrap) {
        entries.removeAll()
        guard let candies = wrap.historyCandies where !candies.isEmpty else { return }
        var _candy: Candy?
        var item: HistoryItem!
        for candy in candies {
            if let _candy = _candy {
                if _candy.createdAt.isSameDay(candy.createdAt) {
                    item.entries.append(candy)
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
    
    private func _addCandy(candy: Candy) -> (item: HistoryItem, added: Bool) {
        let items = entries
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
        return entries.first?.entries.last?.createdAt
    }
    
    override func olderPaginationDate() -> NSDate? {
        return nil
    }
    
    func addCandies(candies: [Candy]) {
        var added = false
        var items = Set<HistoryItem>()
        for candy in candies {
            let result = _addCandy(candy)
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
        entries.all({ $0.sort() })
        didChange()
    }
    
    func removeCandy(candy: Candy) {
        for (itemIndex, item) in entries.enumerate() {
            if let index = item.entries.indexOf(candy) {
                item.entries.removeAtIndex(index)
                if item.entries.count == 0 {
                    entries.removeAtIndex(itemIndex)
                }
                didChange()
                break
            }
        }
    }
    
    func sortCandy(candy: Candy) {
        if let item = entries[{ $0.entries.contains(candy) }] {
            item.sort()
        } else {
            _addCandy(candy)
        }
    }
    
    func addCandy(candy: Candy) {
        let result = _addCandy(candy)
        result.item.sort()
        if result.added {
            didChange()
        }
    }
    
    func itemWithCandy(candy: Candy?) -> HistoryItem? {
        guard let candy = candy else { return nil }
        return entries[{ $0.entries.contains(candy) }]
    }
    
    func notifier(notifier: OrderedNotifier, shouldNotifyBeforeReceiver receiver: AnyObject) -> Bool {
        return true
    }
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        guard let candy = entry as? Candy else { return }
        addCandy(candy)
        if let contributor = candy.contributor where contributor.current {
            didChange()
        }
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        guard let candy = entry as? Candy else { return }
        removeCandy(candy)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        guard let candy = entry as? Candy else { return }
        sortCandy(candy)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry.container
    }
}

class HistoryItem: List<Candy>, ListEntry {
    
    unowned var history: History
    
    var offset = CGPoint.zero
    
    var date: NSDate
    
    init(candy: Candy, history: History) {
        self.history = history
        date = candy.createdAt
        entries.append(candy)
    }
    
    override func sort() {
        entries.sortInPlace({ $0.createdAt < $1.createdAt })
    }
    
    func listSort(entry: HistoryItem) -> Bool {
        return listSortDate() > entry.listSortDate()
    }
    
    func listSortDate() -> NSDate {
        return date
    }
    
    func listEntryEqual(entry: HistoryItem) -> Bool {
        return self == entry
    }
    
    func addCandy(candy: Candy) -> Bool {
        if !entries.contains(candy) {
            entries.append(candy)
            return true
        } else {
            return false
        }
    }
}
