//
//  Candy.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(Candy)
final class Candy: Contribution {

    override class func entityName() -> String { return "Candy" }
    
    override class func containerType() -> Entry.Type? { return Wrap.self }
    
    override class func contentTypes() -> [Entry.Type]? { return [Comment.self] }

    override var container: Entry? {
        get { return wrap }
        set {
            if let wrap = newValue as? Wrap {
                self.wrap = wrap
            }
        }
    }
    
    private var _latestComment: Comment?
    var latestComment: Comment? {
        if _latestComment == nil {
            _latestComment = comments.sort({ $0.createdAt > $1.createdAt }).first
        }
        return _latestComment
    }
    
    override func remove() {
        if let wrap = wrap where unread && wrap.numberOfUnreadInboxItems > 0 {
            wrap.numberOfUnreadInboxItems -= 1
            wrap.notifyOnUpdate(.InboxChanged)
        }
        for comment in comments where comment.unread {
            comment.decrementBadgeIfNeeded()
        }
        super.remove()
    }
    
    private var obsering = false
    
    deinit {
        if obsering {
            removeObserver(self, forKeyPath: "comments", context: nil)
            removeObserver(self, forKeyPath: "updatedAt", context: nil)
        }
    }
    
    override func awakeFromFetch() {
        super.awakeFromFetch()
        addObserver(self, forKeyPath: "comments", options: .New, context: nil)
        addObserver(self, forKeyPath: "updatedAt", options: .New, context: nil)
        obsering = true
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if asset == nil {
            asset = Asset()
        }
        addObserver(self, forKeyPath: "comments", options: .New, context: nil)
        addObserver(self, forKeyPath: "updatedAt", options: .New, context: nil)
        obsering = true
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "comments" {
            _latestComment = nil
        } else if keyPath == "updatedAt" {
            wrap?.recentCandies = nil
            wrap?.historyCandies = nil
        }
    }
    
    func sortedComments() -> [Comment] {
        return comments.sort({ $0.createdAt < $1.createdAt }) ?? []
    }
        
    override var canBeUploaded: Bool { return wrap?.uploaded == true }
    
    override var deletable: Bool { return super.deletable || (wrap?.deletable ?? false) }
    
    var mediaType: MediaType {
        get { return MediaType(rawValue: type) ?? .Photo }
        set { type = newValue.rawValue }
    }
    
    var isVideo: Bool { return mediaType == .Video }
    
    override class func prefetchDescriptors(inout descriptors: Set<EntryDescriptor>, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(&descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(&descriptors, inDictionary: dictionary?["editor"] as? [String:AnyObject])
        Comment.prefetchDescriptors(&descriptors, inArray: dictionary?["comments"] as? [[String:AnyObject]])
    }
    
    var typedComment: String?
    
    func fetchAsset(success: () -> ()) {
        if let asset = asset {
            if UIApplication.sharedApplication().applicationState == .Background {
                let task = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
                asset.fetch({
                    UIApplication.sharedApplication().endBackgroundTask(task)
                })
                success()
            } else {
                asset.fetch(success)
            }
        } else {
            success()
        }
    }
    
    let ratio: CGFloat = randomRatio()
}

func randomRatio() -> CGFloat {
    return ((200 + CGFloat(arc4random_uniform(200))) / (200 + CGFloat(arc4random_uniform(200))))
}
