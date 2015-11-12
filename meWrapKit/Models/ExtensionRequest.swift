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
    
    override class func serializationKey() -> String {
        return "request"
    }
    
    override class func archivableProperties() -> Set<String> {
        return ["action", "userInfo"]
    }
}
