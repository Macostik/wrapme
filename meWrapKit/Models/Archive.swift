//
//  Archive.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class Archive: NSObject, NSCoding, NSCopying {
    class func archivableProperties() -> Set<String> {
        return []
    }
    
    required override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        for property in self.dynamicType.archivableProperties() {
            if let value = aDecoder.decodeObjectForKey(property) {
                setValue(value, forKey: property)
            }
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        for property in self.dynamicType.archivableProperties() {
            aCoder.encodeObject(valueForKey(property), forKey: property)
        }
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = self.dynamicType.init()
        for property in self.dynamicType.archivableProperties() {
            if let value = self.valueForKey(property) {
                if let value = value as? NSCopying {
                    copy.setValue(value.copyWithZone(nil), forKey: property)
                } else{
                    copy.setValue(value, forKey: property)
                }
                
            }
        }
        return copy
    }
}

extension NSObject {
    func archive() -> NSData? {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }
    
    class func unarchive(data: NSData?) -> Self? {
        return unarchive(self, data: data)
    }
    
    private class func unarchive<T>(type: T.Type, data: NSData?) -> T? {
        if let data = data {
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? T
        } else {
            return nil
        }
    }

}
