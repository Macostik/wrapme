//
//  History.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/4/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class History: WLPaginatedSet {
    
    weak var wrap: Wrap?
    
    required init(wrap: Wrap) {
        super.init()
        paginationDateKeyPath = "createdAt"
        Candy.notifier().addReceiver(self)
        sortComparator = comparatorByCreatedAt
        self.wrap = wrap
        fetchCandies()
        request = PaginatedRequest.candies(wrap)
    }
    
    func fetchCandies() {
        entries.removeAllObjects()
        if let candies = wrap?.historyCandies {
            entries.addObjectsFromArray(candies)
        }
    }
    
    override func resetEntries(entries: Set<NSObject>!) {
        fetchCandies()
        didChange()
    }
}

extension History: EntryNotifying {
    
    func broadcasterOrderPriority(broadcaster: WLBroadcaster!) -> Int {
        return WLBroadcastReceiverOrderPriorityPrimary
    }
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        addEntry(entry)
        if let contributor = (entry as? Candy)?.contributor where contributor.current {
            didChange()
        }
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        removeEntry(entry)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        sort(entry)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry.container
    }
}
