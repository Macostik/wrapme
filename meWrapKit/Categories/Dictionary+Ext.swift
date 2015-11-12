//
//  Dictionary+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/6/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension NSDictionary {
    
    func objectForPossibleKeys(keys: [NSCopying]) -> AnyObject? {
        for key in keys {
            if let object = self[key] {
                return object
            }
        }
        return nil
    }
    
    func numberForKey(key: NSCopying) -> NSNumber? {
        if let number = self[key] as? NSNumber {
            return number
        } else if let string = self[key] as? String, let number = Double(string) {
            return NSNumber(double: number)
        } else {
            return nil
        }
    }
    
    func stringForKey(key: NSCopying) -> String? {
        if let string = self[key] as? String {
            return string
        } else if let number = self[key] as? NSNumber {
            return number.stringValue
        } else {
            return nil
        }
    }
    
    func dateForKey(key: NSCopying) -> NSDate? {
        if let timestamp = self[key] as? NSTimeInterval {
            return NSDate(timeIntervalSince1970: timestamp)
        } else {
            return nil
        }
    }
    
    func arrayForKey(key: NSCopying) -> NSArray? {
        return self[key] as? NSArray
    }
    
    func dictionaryForKey(key: NSCopying) -> NSDictionary? {
        return self[key] as? NSDictionary
    }

}

extension NSMutableDictionary {
    func trySetObject(object: AnyObject?, forKey key: NSCopying) {
        if let object = object {
            self[key] = object
        }
    }
}

extension Dictionary {
    
    func dateForKey(key: Key) -> NSDate? {
        if let string = self[key] as? String, let timestamp = Double(string) {
            return NSDate(timeIntervalSince1970: timestamp)
        } else {
            return nil
        }
    }
    
}