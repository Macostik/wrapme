//
//  Wrap.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

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
            if let candies = candies as? Set<Candy> {
                _cover = candies.sort({ (comment1, comment2) -> Bool in
                    return comment1.createdAt.timeIntervalSince1970 > comment2.createdAt.timeIntervalSince1970
                }).first
            }
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
}
