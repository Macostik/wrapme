//
//  ExtensionResponse.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class ExtensionResponse: ExtensionMessage {
    var success = false
    var message: String?
    
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary);
        message = dictionary["message"] as? String
        success = (dictionary["success"] as? Bool) ?? false
    }
    
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        if let message = message {
            dictionary["message"] = message
        }
        dictionary["success"] = success
        return dictionary
    }
    
    convenience init(success: Bool, message: String?, userInfo: Dictionary<String, AnyObject>?) {
        self.init()
        self.success = success
        self.message = message
        self.userInfo = userInfo
    }
    
    class func success(message: String?) -> ExtensionResponse {
        return ExtensionResponse(success: true, message: message, userInfo: nil)
    }
    
    class func success(message: String?, userInfo: Dictionary<String, AnyObject>?) -> ExtensionResponse {
        return ExtensionResponse(success: true, message: nil, userInfo: userInfo)
    }
    
    class func failure() -> ExtensionResponse {
        return ExtensionResponse(success: false, message: nil, userInfo: nil)
    }
    
    class func failure(message: String?) -> ExtensionResponse {
        return ExtensionResponse(success: false, message: message, userInfo: nil)
    }
    
    class func failure(message: String?, userInfo: Dictionary<String, AnyObject>?) -> ExtensionResponse {
        return ExtensionResponse(success: false, message: nil, userInfo: userInfo)
    }
}
