//
//  NSObject+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension NSObject {
    
    func associatedObjectForKey(key: UnsafePointer<Void>) -> AnyObject? {
        return objc_getAssociatedObject(self, key)
    }
    
    func setAssociatedObject(object: AnyObject?, forKey key: UnsafePointer<Void>) {
        objc_setAssociatedObject(self, key, object, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func enqueueSelector(selector: Selector) {
        enqueueSelector(selector, delay: 0.5)
    }
    
    func enqueueSelector(selector: Selector, delay: NSTimeInterval) {
        enqueueSelector(selector, argument: nil, delay: delay)
    }

    func enqueueSelector(selector: Selector, argument: AnyObject?, delay: NSTimeInterval) {
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