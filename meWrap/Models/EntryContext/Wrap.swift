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
        enum Type: String {
            case Message = "message"
            case Join = "join"
        }
        
        var type: Type
        var text: String?
        var user: User?
        
        init(type: Type) {
            self.type = type
        }
    }
    
    var broadcaster: User?
    weak var wrap: Wrap?
    var title = ""
    var url = ""
    var channel = ""
    var numberOfViewers = 0
    
    var events = [Event]()
    
    func insert(event: Event) {
        events.insert(event, atIndex: 0)
        if (events.count > 3) {
            events.removeLast()
        }
    }
}

@objc(Wrap)
class Wrap: Contribution {
    
    var broadcasters = [User]()

    override class func entityName() -> String {
        return "Wrap"
    }
    
    override class func contentEntityNames() -> Set<String>? {
        return [Candy.entityName()]
    }
    
    private var _historyCandies: NSArray?
    var historyCandies: NSArray? {
        get {
            if _historyCandies == nil {
                if let candies = candies {
                    _historyCandies = (candies.array() as NSArray).sortByCreatedAt()
                }
            }
            return _historyCandies
        }
        set {
            _historyCandies = newValue
        }
    }
    
    private var _recentCandies: NSArray?
    var recentCandies: NSArray? {
        get {
            if _recentCandies == nil {
                if let candies = candies {
                    _recentCandies = (candies.array() as NSArray).sortByUpdatedAt()
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
            _cover = (candies as? Set<Candy>)?.sort({ $0.updatedAt > $1.updatedAt }).first
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
    
    override var picture: Asset? {
        get {
            return cover?.picture
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
}
