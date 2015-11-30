//
//  ExtensionRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class ExtensionRequest: ExtensionMessage {
    
    var action: String?
    
    convenience init(action: String, userInfo: Dictionary<String, AnyObject>?) {
        self.init()
        self.action = action
        self.userInfo = userInfo
    }
    
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary);
        action = dictionary["action"] as? String
    }
    
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        if let action = action {
            dictionary["action"] = action
        }
        return dictionary
    }
    
    func serializedURL() -> NSURL? {
        if let string = serialize() {
            let components = NSURLComponents()
            components.scheme = "mewrap"
            components.host = "extension.com"
            components.path = "/request/\(string)"
            return components.URL
        } else {
            return nil
        }
    }
}
