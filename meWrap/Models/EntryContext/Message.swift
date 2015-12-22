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
class Message: Contribution {

    override class func entityName() -> String { return "Message" }
    
    override class func containerEntityName() -> String? { return Wrap.entityName() }

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
            if unread && createdAt > NSDate.dayAgo() {
                wrap.numberOfUnreadMessages++
            } else {
                wrap.numberOfUnreadMessages--
            }
            wrap.notifyOnUpdate(.NumberOfUnreadMessagesChanged)
        }
    }
    
    lazy var chatMetadata = ChatMetadata()
}

class ChatMetadata: NSObject {
    var containsName = false
    var containsDate = false
    var isGroup = false
}
