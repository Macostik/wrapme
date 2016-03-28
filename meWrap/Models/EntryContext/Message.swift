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
    
    lazy var chatMetadata = ChatMetadata()
}

struct ChatMetadata {
    var containsName = false
    var containsDate = false
    var isGroup = false
    var height: CGFloat?
}
