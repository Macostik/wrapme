//
//  RecentUpdateList.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import CoreData

class RecentUpdate: NSObject, ListEntry {
    
    var event: Event
    
    var contribution: Contribution
    
    var date: NSDate {
        return event == .Update ? contribution.editedAt : contribution.createdAt
    }
    
    init(event: Event, contribution: Contribution) {
        self.event = event
        self.contribution = contribution
        super.init()
    }
    
    func listSortDate() -> NSDate {
        return date
    }
}

@objc protocol RecentUpdateListNotifying {
    optional func recentUpdateListUpdated(list: RecentUpdateList)
}

class RecentUpdateList: Notifier {
    
    var unreadCount = 0
    
    static var sharedList = RecentUpdateList()
    
    var updates: [RecentUpdate]?
    
    private var candyPredicate = "wrap IN %@ AND createdAt >= %@ AND contributor != nil AND contributor != %@"
    private var updatesPredicate = "wrap IN %@ AND editedAt >= %@ AND editor != nil AND editor != %@"
    private var commentPredicate = "candy.wrap IN %@ AND createdAt >= %@ AND contributor != nil AND contributor != %@"
    
    private var wrapCounters = [String:Int]()
    
    override init() {
        super.init()
        Comment.notifier().addReceiver(self)
        Candy.notifier().addReceiver(self)
        Wrap.notifier().addReceiver(self)
    }
    
    func update(success: Block?, failure: FailureBlock?) {
        guard let user = User.currentUser else {
            failure?(nil)
            return
        }
        let date = NSDate.dayAgo()
        var contributions = [AnyObject]()
        var uids = [NSManagedObjectID]()
        if let wraps = user.wraps as? Set<Wrap> {
            uids = wraps.map({ $0.objectID })
        }
        Comment.fetch().query(commentPredicate, uids, date, user).execute { (result) -> Void in
            contributions.appendContentsOf(result)
            Candy.fetch().query(self.candyPredicate, uids, date, user).execute({ (result) -> Void in
                contributions.appendContentsOf(result)
                Candy.fetch().query(self.updatesPredicate, uids, date, user).execute({ (result) -> Void in
                    self.handleContributions(contributions, updates: result)
                    success?()
                })
            })
        }
    }
    
    func handleContributions(contributions: [AnyObject], updates: [AnyObject]) {
        var wrapCounters = [String:Int]()
        var unreadCount = 0
        var events = [RecentUpdate]()
        for contribution in contributions {
            if let contribution = contribution as? Contribution where contribution.valid {
                events.append(RecentUpdate(event: .Add, contribution: contribution))
                if contribution.unread {
                    unreadCount++
                    if let candy = contribution as? Candy, let wrap = candy.wrap {
                        if let count = wrapCounters[wrap.uid] {
                            wrapCounters[wrap.uid] = count + 1
                        } else {
                            wrapCounters[wrap.uid] = 1
                        }
                    }
                }
            }
        }
        
        for contribution in updates {
            if let contribution = contribution as? Contribution where contribution.valid {
                events.append(RecentUpdate(event: .Update, contribution: contribution))
                if contribution.unread {
                    unreadCount++
                }
            }
        }
        self.unreadCount = unreadCount
        self.wrapCounters = wrapCounters
        self.updates = events.sort({ $0.date > $1.date })
    }
    
    func refreshCount(success: (Int -> Void)?, failure: FailureBlock?) {
        update({ () -> Void in
            success?(self.unreadCount)
            }, failure: failure)
    }
    
    func unreadCandiesCountForWrap(wrap: Wrap) -> Int {
        return wrapCounters[wrap.uid] ?? 0
    }
}

extension RecentUpdateList: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        guard let contributor = (entry as? Contribution)?.contributor where !contributor.current else {
            return
        }
        update({ () -> Void in
            self.notify { (receiver) -> Void in
                receiver.recentUpdateListUpdated?(self)
            }
            }, failure: nil)
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        guard let contributor = (entry as? Contribution)?.contributor where !contributor.current else {
            return
        }
        update({ () -> Void in
            self.notify { (receiver) -> Void in
                receiver.recentUpdateListUpdated?(self)
            }
            }, failure: nil)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        update({ () -> Void in
            self.notify { (receiver) -> Void in
                receiver.recentUpdateListUpdated?(self)
            }
            }, failure: nil)
    }
    
    func broadcasterOrderPriority(broadcaster: WLBroadcaster!) -> Int {
        return WLBroadcastReceiverOrderPriorityPrimary
    }
}
