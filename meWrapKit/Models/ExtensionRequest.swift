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
    
    override class func archivableProperties() -> Set<String> {
        return ["action", "userInfo"]
    }
    
    func serializedURL() -> NSURL? {
        if let string = serialize() {
            let components = NSURLComponents()
            components.scheme = "mewrap"
            components.host = "extension.com"
            components.path = "/request?request=\(string)"
            return components.URL
        } else {
            return nil
        }
    }
}
