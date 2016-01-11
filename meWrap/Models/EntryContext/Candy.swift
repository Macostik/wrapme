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
class Candy: Contribution {

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
        get {
            if _latestComment == nil {
                guard let comments = comments as? Set<Comment> else {
                    return nil
                }
                _latestComment = comments.sort({ $0.createdAt.later($1.createdAt) }).first
            }
            return _latestComment
        }
        set {
            _latestComment = newValue
        }
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
        if let comments = comments as? Set<Comment> {
            return comments.sort({ $0.createdAt < $1.createdAt })
        } else {
            return []
        }
    }
    
    override var uploaded: Bool { return super.uploaded && uid != locuid }
    
    override var canBeUploaded: Bool { return wrap?.uploading == nil }
    
    override var deletable: Bool { return super.deletable || (wrap?.deletable ?? false) }
    
    var mediaType: MediaType {
        get { return MediaType(rawValue: type) ?? .Photo }
        set { type = newValue.rawValue }
    }
    
    var isVideo: Bool { return mediaType == .Video }
}
