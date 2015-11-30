//
//  ExtensionMessage.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class ExtensionMessage: NSObject {
    
    required override init() {
    }
    
    class func fromDictionary(dictionary: [String : AnyObject]) -> Self {
        let message = self.init()
        message.fromDictionary(dictionary)
        return message
    }
    
    func fromDictionary(dictionary: [String : AnyObject]) {
        
    }
    
    func toDictionary() -> [String : AnyObject] {
        return [String : AnyObject]()
    }
    
    class func deserialize(string: String) -> Self? {
        return deserialize(self, string: string)
    }
    
    class func deserialize<T>(type: T.Type, string: String) -> T? {
        guard let data = NSData(base64EncodedString: string, options: .IgnoreUnknownCharacters) else {
            return nil
        }
        do {
            guard let dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String : AnyObject] else {
                return nil
            }
            return fromDictionary(dictionary) as? T
        } catch {
            return nil
        }
    }
    
    func serialize() -> String? {
        do {
            let dictionary = toDictionary()
            let data = try NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions())
            return data.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        } catch {
            return nil
        }
    }
}
