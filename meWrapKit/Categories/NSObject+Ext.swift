//
//  NSObject+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension NSObject {
    
    func enqueueSelector(selector: Selector, argument: AnyObject? = nil, delay: NSTimeInterval = 0.5) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: selector, object: argument)
        performSelector(selector, withObject: argument, afterDelay: delay)
    }
    
    class func loadFromNib(name: String) -> Self? {
        return loadFromNib(name, owner: nil)
    }
    
    class func loadFromNib(name: String, owner: AnyObject?) -> Self? {
        return loadFromNib(self, name: name, owner: owner)
    }
    
    class func loadFromNib<T>(type: T.Type, name: String, owner: AnyObject?) -> T? {
        let objects = NSBundle.mainBundle().loadNibNamed(name, owner: owner, options: nil)
        for object in objects {
            if let object = object as? T {
                return object
            }
        }
        return nil
    }
}