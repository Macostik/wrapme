//
//  Comment.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(Comment)
class Comment: Contribution {

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
    
    override var canBeUploaded: Bool { return candy?.uploading == nil }
    
    override var deletable: Bool { return super.deletable || (candy?.deletable ?? false) }
    
    override var asset: Asset? {
        get { return candy?.asset }
        set { }
    }
    
    override func willBecomeUnread(unread: Bool) {
        if let candy = candy, let wrap = candy.wrap {
            if unread {
                if createdAt > NSDate.dayAgo() {
                    wrap.numberOfUnreadInboxItems++
                }
            } else if wrap.numberOfUnreadInboxItems > 0 {
                wrap.numberOfUnreadInboxItems--
            }
            wrap.notifyOnUpdate(.InboxChanged)
        }
    }
    
    override func remove() {
        if let wrap = candy?.wrap where unread && wrap.numberOfUnreadInboxItems > 0 {
            wrap.numberOfUnreadInboxItems--
            wrap.notifyOnUpdate(.InboxChanged)
        }
        super.remove()
    }
}
