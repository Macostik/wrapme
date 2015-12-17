//
//  Wrap.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

class LiveBroadcast: NSObject {
    
    class Event {
        
        unowned var broadcast: LiveBroadcast
        
        enum Type: String {
            case Message = "message"
            case Join = "join"
        }
        
        var type: Type
        var text: String?
        var user: User?
        
        init(type: Type, broadcast: LiveBroadcast) {
            self.type = type
            self.broadcast = broadcast
        }
    }
    
    var broadcaster: User?
    weak var wrap: Wrap?
    var title = ""
    var url = ""
    var channel = ""
    var numberOfViewers = 1
    
    var events = [Event]()
    
    func insert(event: Event) {
        events.insert(event, atIndex: 0)
        if (events.count > 3) {
            events.removeLast()
        }
    }
    
    func remove(event: Event) {
        if let index = events.indexOf({ $0 === event }) {
            events.removeAtIndex(index)
        }
    }
}

@objc(Wrap)
class Wrap: Contribution {
    
   static var ContentTypeRecent = "recent_candies"
    
    override class func entityName() -> String {
        return "Wrap"
    }
    
    override class func contentEntityNames() -> Set<String>? {
        return [Candy.entityName()]
    }
    
    private var _historyCandies: [Candy]?
    var historyCandies: [Candy]? {
        get {
            if _historyCandies == nil {
                _historyCandies = (candies as? Set<Candy>)?.sort({ $0.createdAt < $1.createdAt })
            }
            return _historyCandies
        }
        set {
            _historyCandies = newValue
        }
    }
    
    private var _recentCandies: [Candy]?
    var recentCandies: [Candy]? {
        get {
            if _recentCandies == nil {
                if let candies = candies {
                    _recentCandies = (candies as? Set<Candy>)?.sort({ $0.updatedAt > $1.updatedAt })
                }
            }
            return _recentCandies
        }
        set {
            _recentCandies = newValue
        }
    }
    
    private var _cover: Candy?
    var cover: Candy? {
        if _cover == nil {
            _cover = recentCandies?.first
        }
        return _cover
    }
    
    private var obsering = false
    
    deinit {
        if obsering {
            removeObserver(self, forKeyPath: "candies", context: nil)
        }
    }
    
    override func awakeFromFetch() {
        super.awakeFromFetch()
        addObserver(self, forKeyPath: "candies", options: .New, context: nil)
        obsering = true
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        addObserver(self, forKeyPath: "candies", options: .New, context: nil)
        obsering = true
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "candies" {
            _recentCandies = nil
            _historyCandies = nil
            _cover = nil
        }
    }
    
    override var asset: Asset? {
        get {
            return cover?.asset
        }
        set {
        }
    }
    
    var isContributing: Bool {
        guard let currentUser = User.currentUser, let contributors = contributors else {
            return false
        }
        return contributors.containsObject(currentUser) ?? false
    }
    
    var isFirstCreated: Bool {
        guard let currentUser = User.currentUser else {
            return false
        }
        guard let contributions = currentUser.contributions as? Set<Entry> else {
            return false
        }
        guard let wraps = currentUser.wraps as? Set<Entry> else {
            return false
        }
        let contributedWraps = contributions.intersect(wraps)
        return contributedWraps.contains(self) && contributedWraps.count == 1
    }
    
    var requiresFollowing: Bool {
        return isPublic && !isContributing
    }
    
    var mutableContributors: NSMutableSet {
        return mutableSetValueForKey("contributors")
    }
    
    var liveBroadcasts = [LiveBroadcast]()
    
    func addBroadcast(broadcast: LiveBroadcast) -> LiveBroadcast {
        if let index = liveBroadcasts.indexOf({ $0.channel == broadcast.channel }) {
            let _broadcast = liveBroadcasts[index]
            _broadcast.title = broadcast.title
            _broadcast.numberOfViewers = broadcast.numberOfViewers
            notifyOnUpdate(.LiveBroadcastsChanged)
            return _broadcast
        } else {
            liveBroadcasts.append(broadcast)
            notifyOnUpdate(.LiveBroadcastsChanged)
            return broadcast
        }
    }
    
    func removeBroadcast(broadcast: LiveBroadcast) {
        if let index = liveBroadcasts.indexOf({ $0.channel == broadcast.channel }) {
            liveBroadcasts.removeAtIndex(index)
        }
        notifyOnUpdate(.LiveBroadcastsChanged)
    }
    
    private var _numberOfUnreadMessages: Int?
    var numberOfUnreadMessages: Int {
        get {
            if let number = _numberOfUnreadMessages {
                return number
            } else {
                let dayAgo = NSDate.dayAgo()
                let number = (messages as? Set<Message>)?.filter({ $0.unread && $0.createdAt > dayAgo }).count ?? 0
                _numberOfUnreadMessages = number
                return number
            }
        }
        set {
            _numberOfUnreadMessages = newValue
        }
    }
}
