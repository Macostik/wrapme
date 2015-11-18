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

    override class func entityName() -> String {
        return "Candy"
    }
    
    override class func containerEntityName() -> String? {
        return Wrap.entityName()
    }

    override var container: Entry? {
        get {
            return wrap
        }
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
                _latestComment = comments.sort({ (comment1, comment2) -> Bool in
                    return comment1.updatedAt.timeIntervalSince1970 > comment2.updatedAt.timeIntervalSince1970
                }).first
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
    
    func sortedComments() -> [Comment]? {
        if let comments = comments as? Set<Comment> {
            return comments.sort({ (comment1, comment2) -> Bool in
                return comment1.createdAt.timeIntervalSince1970 > comment2.createdAt.timeIntervalSince1970
            })
        } else {
            return nil
        }
    }
    
    override var uploaded: Bool {
        return super.uploaded && identifier != uploadIdentifier
    }
    
    override var canBeUploaded: Bool {
        return wrap?.uploading == nil
    }
    
    override var deletable: Bool {
        return super.deletable || (wrap?.deletable ?? false)
    }
    
    var mediaType: MediaType {
        get {
            return MediaType(rawValue: type) ?? .Photo
        }
        set {
            type = newValue.rawValue
        }
    }
    
    var isVideo: Bool {
        return mediaType == .Video
    }
}
