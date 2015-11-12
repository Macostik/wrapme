//
//  ExtensionMessage.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class ExtensionMessage: Archive {
    var userInfo: Dictionary<String, AnyObject>?
    
    override class func archivableProperties() -> Set<String> {
        return ["userInfo"]
    }
    
    class func serializationKey() -> String {
        return ""
    }
    
    class func deserialize(dictionary: Dictionary<String, NSData>) -> ExtensionMessage? {
        return unarchive(dictionary[serializationKey()]) as? ExtensionMessage
    }
    
    func serialize() -> Dictionary<String, NSData>? {
        if let data = archive() {
            return [self.dynamicType.serializationKey():data]
        } else {
            return nil
        }
    }
}
