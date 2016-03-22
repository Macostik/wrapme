//
//  Message.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(Message)
final class Message: Contribution {

    override class func entityName() -> String { return "Message" }
    
    override class func containerType() -> Entry.Type? { return Wrap.self }

    override var container: Entry? {
        get { return wrap }
        set {
            if let wrap = newValue as? Wrap {
                self.wrap = wrap
            }
        }
    }
    
    override var asset: Asset? {
        get { return contributor?.avatar }
        set { }
    }
    
    override func willBecomeUnread(unread: Bool) {
        if let wrap = wrap {
            if unread {
                if createdAt > NSDate.dayAgo() {
                    wrap.numberOfUnreadMessages += 1
                }
            } else if wrap.numberOfUnreadMessages > 0 {
                wrap.numberOfUnreadMessages -= 1
            }
            wrap.notifyOnUpdate(.NumberOfUnreadMessagesChanged)
        }
    }
    
    lazy var chatMetadata = ChatMetadata()
}

struct ChatMetadata {
    var containsName = false
    var containsDate = false
    var isGroup = false
    var height: CGFloat?
}
