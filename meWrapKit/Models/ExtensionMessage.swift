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
    
    class func deserialize(string: String) -> Self? {
        return deserialize(self, string: string)
    }
    
    class func deserialize<T>(type: T.Type, string: String) -> T? {
        if let data = NSData(base64EncodedString: string, options: .IgnoreUnknownCharacters) {
            return unarchive(data) as? T
        } else {
            return nil
        }
    }
    
    func serialize() -> String? {
        if let data = archive() {
            return data.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        } else {
            return nil
        }
    }
}
