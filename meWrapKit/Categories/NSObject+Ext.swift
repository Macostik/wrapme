//
//  NSObject+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

func loadFromNib<T>(name: String, owner: AnyObject? = nil) -> T? {
    let objects = NSBundle.mainBundle().loadNibNamed(name, owner: owner, options: nil)
    for object in objects {
        if let object = object as? T {
            return object
        }
    }
    return nil
}

extension NSObject {
    
    func enqueueSelector(selector: Selector, argument: AnyObject? = nil, delay: NSTimeInterval = 0.5) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: selector, object: argument)
        performSelector(selector, withObject: argument, afterDelay: delay)
    }
}