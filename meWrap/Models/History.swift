//
//  History.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/4/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class History: PaginatedList<HistoryItem>, PaginatedListNotifying {
    
    weak var wrap: Wrap?
    
    private var historyCandies: PaginatedList<Candy>
    
    required init(wrap: Wrap) {
        historyCandies = specify(PaginatedList(), {
            $0.request = API.candies(wrap)
            $0.sorter = { $0.createdAt > $1.createdAt }
            $0.entries = wrap.historyCandies
            $0.newerThen = { $0.first?.createdAt }
            $0.olderThen = { $0.last?.createdAt }
        })
        super.init()
        Candy.notifier().addReceiver(self)
        self.wrap = wrap
        fetchCandies(wrap)
        historyCandies.addReceiver(self)
    }
    
    override var completed: Bool {
        get { return historyCandies.completed }
        set { historyCandies.completed = newValue }
    }
    
    override func send(type: PaginatedRequestType, success: ([HistoryItem] -> ())?, failure: FailureBlock?) {
        historyCandies.send(type, success: { [weak self] candies in
            if let history = self {
                history.addCandies(candies)
                success?(history.entries)
            }
            }, failure: failure)
    }
    
    func listChanged<T : Equatable>(list: List<T>) {
        notify({ ($0 as? ListNotifying)?.listChanged(self) })
    }
    
    func paginatedListDidStartLoading<T : Equatable>(list: PaginatedList<T>) {
        notify({ ($0 as? PaginatedListNotifying)?.paginatedListDidStartLoading(self) })
    }
    
    func paginatedListDidFinishLoading<T : Equatable>(list: PaginatedList<T>) {
        notify({ ($0 as? PaginatedListNotifying)?.paginatedListDidFinishLoading(self) })
    }
    
    private func fetchCandies(wrap: Wrap) {
        let candies = historyCandies.entries
        guard !candies.isEmpty else { return }
        var items = [HistoryItem]()
        var _candy: Candy?
        var item: HistoryItem!
        for candy in candies {
            if let _candy = _candy {
                if _candy.createdAt.isSameDay(candy.createdAt) {
                    item.entries.insert(candy, atIndex: 0)
                } else {
                    item = HistoryItem(candy: candy, history: self)
                    items.append(item)
                }
            } else {
                item = HistoryItem(candy: candy, history: self)
                items.append(item)
            }
            _candy = candy
        }
        
        entries = items
    }
    
    private func _addCandy(candy: Candy) -> (item: HistoryItem, added: Bool) {
        var items = entries
        if let item = items.last where item.date.isSameDay(candy.createdAt) {
            return (item, item.addCandy(candy))
        } else {
            for item in items where item.date.isSameDay(candy.createdAt) {
                return (item, item.addCandy(candy))
            }
        }
        let item = HistoryItem(candy: candy, history: self)
        items.append(item)
        items = items.sort({ $0.date > $1.date })
        entries = items
        return (item, true)
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
            didChange()
        } else {
            addCandy(candy)
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

func ==(lhs: HistoryItem, rhs: HistoryItem) -> Bool {
    return lhs.date == rhs.date
}

class HistoryItem: List<Candy> {
    
    unowned var history: History
    
    var offset = CGPoint.zero
    
    var date: NSDate
        
    init(candy: Candy, history: History) {
        self.history = history
        date = candy.createdAt
        super.init()
        sorter = { $0.createdAt < $1.createdAt }
        entries.append(candy)
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
