//
//  Comment.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

enum CommentType {
    case Text, Photo, Video
}

@objc(Comment)
final class Comment: Contribution {

    override class func entityName() -> String { return "Comment" }
    
    override class func containerType() -> Entry.Type? { return Candy.self }
    
    override var container: Entry? {
        get { return candy }
        set {
            if let candy = newValue as? Candy {
                self.candy = candy
            }
        }
    }
    
    override var canBeUploaded: Bool { return candy?.uploaded == true }
    
    override var deletable: Bool { return super.deletable || (candy?.deletable ?? false) }
    
    func decrementBadgeIfNeeded() {
        if let wrap = candy?.wrap where unread && wrap.numberOfUnreadInboxItems > 0 {
            wrap.numberOfUnreadInboxItems -= 1
            wrap.notifyOnUpdate(.InboxChanged)
        }
    }
    
    override func remove() {
        decrementBadgeIfNeeded()
        super.remove()
    }
    
    func type() -> CommentType {
        if let asset = asset {
            return asset.type == .Video ? .Video : .Photo
        } else {
            return .Text
        }
    }
}
