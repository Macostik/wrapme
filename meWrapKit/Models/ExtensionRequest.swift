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
    
    var parameters: [String : AnyObject]?
    
    convenience init(action: String, parameters: [String : AnyObject]?) {
        self.init()
        self.action = action
        self.parameters = parameters
    }
    
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary);
        action = dictionary["action"] as? String
        parameters = dictionary["parameters"] as? [String : AnyObject]
    }
    
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        if let action = action {
            dictionary["action"] = action
        }
        if let parameters = parameters {
            dictionary["parameters"] = parameters
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

class ExtensionReply: ExtensionMessage {
    
    var reply: [String : AnyObject]?
    
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary);
        reply = dictionary["reply"] as? [String : AnyObject]
    }
    
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        if let reply = reply {
            dictionary["reply"] = reply
        }
        return dictionary
    }
    
    convenience init(reply: [String : AnyObject]) {
        self.init()
        self.reply = reply
    }
}

class ExtensionError: ExtensionMessage {
    
    var message: String?
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary);
        message = dictionary["message"] as? String
    }
    
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        dictionary["message"] = message ?? ""
        return dictionary
    }
    
    convenience init(message: String) {
        self.init()
        self.message = message
    }
    
    func generateError() -> NSError {
        return NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey:message ?? ""])
    }
}
