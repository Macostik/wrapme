//
//  Dictionary+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/6/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension Dictionary {
    
    func dateForKey(key: Key) -> NSDate? {
        if let string = self[key] as? String, let timestamp = Double(string) {
            return NSDate(timeIntervalSince1970: timestamp)
        } else {
            return nil
        }
    }
    
    func objectForPossibleKeys(keys: [Key]) -> Value? {
        for key in keys {
            if let object = self[key] {
                return object
            }
        }
        return nil
    }
}