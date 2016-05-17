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
    
    override var canBeUploaded: Bool {
        if let candy = candy where candy.uploaded == false {
            Logger.log("Comment cannot be uploaded. It's candy: \(candy)")
        }
        return candy?.uploaded == true
    }
    
    override var deletable: Bool { return super.deletable || (candy?.deletable ?? false) }
    
    override var uploaded: Bool { return super.uploaded && uid != locuid }
    
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
    
    func commentType() -> CommentType {
        if let asset = asset where asset.original?.isEmpty == false {
            return asset.type == .Video ? .Video : .Photo
        } else {
            return .Text
        }
    }
    
    var mediaType: MediaType {
        get { return MediaType(rawValue: type) ?? .Photo }
        set { type = newValue.rawValue }
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if asset == nil {
            asset = Asset()
        }
    }
}
