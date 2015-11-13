//
//  NSUserDefaults+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/5/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension NSString {
    
    class func GUID() -> String {
        return NSUUID().UUIDString
    }
    
    var URL: NSURL? {
        return NSURL(string: self as String)
    }
    var fileURL: NSURL? {
        return NSURL(fileURLWithPath: self as String)
    }
    var smartURL: NSURL? {
        if isExistingFilePath {
            return fileURL
        } else {
            return URL
        }
    }
    var isExistingFilePath: Bool {
        if hasPrefix("http") {
            return false
        }
        return NSFileManager.defaultManager().fileExistsAtPath(self as String)
    }
    
    var nonempty: Bool {
        return length > 0
    }
    
    var trim: String {
        return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    private static let emailRegex = "(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
    
    var isValidEmail: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", NSString.emailRegex)
        return predicate.evaluateWithObject(lowercaseString)
    }
    
    var URLQuery: [String:String] {
        
        var parameters = [String:String]()
        if let query = stringByRemovingPercentEncoding {
            for pair in query.componentsSeparatedByString("&") {
                let components = pair.componentsSeparatedByString("&")
                if components.count == 2 {
                    parameters[components[0]] = components[1]
                } else {
                    continue
                }
            }
        }
        
        return parameters
    }
    
    func heightWithFont(font: UIFont, width: CGFloat) -> CGFloat {
        let size = CGSize(width: width, height: CGFloat.max)
        let height = boundingRectWithSize(size, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil).height
        return ceil(height)
    }
    
    func clearPhoneNumber() -> String {
        var phone = ""
        for character in (self as String).characters {
            if character == "+" || "0"..."9" ~= character {
                phone.append(character)
            }
        }
        return phone
    }
    
    var ls: String {
        let string = self as String
        return NSBundle.mainBundle().localizedStringForKey(string, value: string, table: nil)
    }
}
