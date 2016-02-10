//
//  GenericCollections+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension NSArray {
    
    var nonempty: Bool {
        return count > 0
    }
    
    func map(@noescape mapper: AnyObject -> AnyObject?) -> [AnyObject] {
        var array = [AnyObject]()
        for object in self as [AnyObject] {
            if let _object = mapper(object) {
                array.append(_object)
            }
        }
        return array
    }
    
    func selectObject(@noescape selector: AnyObject -> Bool) -> AnyObject? {
        for object in self as [AnyObject] where selector(object) {
            return object
        }
        return nil
    }

}

extension NSSet {
    var nonempty: Bool {
        return count > 0
    }
    
    func map(@noescape mapper: AnyObject -> AnyObject?) -> NSSet {
        let set = NSMutableSet()
        for object in self {
            if let _object = mapper(object) {
                set.addObject(_object)
            }
        }
        return NSSet(set: set)
    }
}

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}