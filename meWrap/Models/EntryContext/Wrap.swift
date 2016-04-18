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
        
        enum Kind: Int {
            case Message
            case Join
            case Info
        }
        
        var kind: Kind
        var text: String?
        var user: User?
        var disappearingBlock: (Void -> Void)?
        
        init(kind: Kind) { self.kind = kind }
    }
    
    var broadcaster: User?
    weak var wrap: Wrap?
    var title: String?
    var streamName = ""
    var viewers = Set<User>()
    
    var events = [Event]()
    
    func insert(event: Event) {
        events.insert(event, atIndex: 0)
        if (events.count > 3) {
            events.removeLast()
        }
        Dispatch.mainQueue.after(4) { [weak self] () -> Void in
            self?.dismiss(event)
        }
    }
    
    func dismiss(event: Event) {
        event.disappearingBlock?()
        remove(event)
    }
    
    func remove(event: Event) {
        if let index = events.indexOf({ $0 === event }) {
            events.removeAtIndex(index)
        }
    }
    
    func displayTitle() -> String {
        if let title = title where !title.isEmpty {
            return title
        } else {
            return "untitled".ls
        }
    }
}

@objc(Wrap)
final class Wrap: Contribution {
    
   static var ContentTypeRecent = "recent_candies"
    
    override class func entityName() -> String { return "Wrap" }
    
    override class func contentTypes() -> [Entry.Type]? { return [Candy.self, Message.self] }
    
    private var _historyCandies: [Candy]?
    var historyCandies: [Candy]! {
        get {
            if _historyCandies == nil {
                _historyCandies = candies.sort({ $0.createdAt > $1.createdAt })
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
                _recentCandies = candies.sort({ $0.updatedAt > $1.updatedAt })
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
        get { return cover?.asset }
        set { }
    }
    
    override var uploaded: Bool { return super.uploaded && uid != locuid }
    
    var isContributing: Bool {
        guard let currentUser = User.currentUser else { return false }
        return contributors.contains(currentUser)
    }
    
    var requiresFollowing: Bool {
        return isPublic && !isContributing
    }
    
    var liveBroadcasts = [LiveBroadcast]()
    
    func addBroadcastIfNeeded(broadcast: LiveBroadcast, notify: Bool = false) {
        if !liveBroadcasts.contains({ $0.streamName == broadcast.streamName }) {
            liveBroadcasts.append(broadcast)
            if notify {
                notifyOnUpdate(.LiveBroadcastsChanged)
            }
        }
    }
    
    func addBroadcast(broadcast: LiveBroadcast) -> LiveBroadcast {
        if let index = liveBroadcasts.indexOf({ $0.streamName == broadcast.streamName }) {
            let _broadcast = liveBroadcasts[index]
            _broadcast.title = broadcast.title
            _broadcast.viewers = broadcast.viewers
            notifyOnUpdate(.LiveBroadcastsChanged)
            return _broadcast
        } else {
            liveBroadcasts.append(broadcast)
            notifyOnUpdate(.LiveBroadcastsChanged)
            return broadcast
        }
    }
    
    func removeBroadcast(broadcast: LiveBroadcast) {
        removeBroadcastWhere(true, block: { $0.streamName == broadcast.streamName })
    }
    
    func removeBroadcastWhere(notify: Bool = false, block: LiveBroadcast -> Bool) {
        if let index = liveBroadcasts.indexOf(block) {
            liveBroadcasts.removeAtIndex(index)
            if notify {
                notifyOnUpdate(.LiveBroadcastsChanged)
            }
        }
    }
    
    func removeBroadcastFrom(user: User, notify: Bool = false) {
        removeBroadcastWhere(notify, block: { $0.broadcaster == user })
    }
    
    lazy var numberOfUnreadMessages: Int = {
        return self.messages.filter({ $0.unread }).count
    }()
    
    lazy var numberOfUnreadInboxItems: Int = {
        var count = 0
        for candy in self.candies {
            if candy.unread {
                count += 1
            }
            if candy.updateUnread {
                count += 1
            }
            for comment in candy.comments where comment.unread {
                count += 1
            }
        }
        return count
    }()
    
    var typedMessage: String?
    
    override class func prefetchDescriptors(inout descriptors: Set<EntryDescriptor>, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(&descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(&descriptors, inArray: dictionary?["contributors"] as? [[String:AnyObject]])
        User.prefetchDescriptors(&descriptors, inDictionary: dictionary?["creator"] as? [String:AnyObject])
        Candy.prefetchDescriptors(&descriptors, inArray: dictionary?["candies"] as? [[String:AnyObject]])
    }
}
