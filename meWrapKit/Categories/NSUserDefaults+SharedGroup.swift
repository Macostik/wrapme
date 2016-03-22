//
//  WLSession.swift
//  meWrap
//
//  Created by Yura Granchenko on 03/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

var _difference : NSTimeInterval = (NSUserDefaults.sharedUserDefaults?["server_time_difference"] as? NSTimeInterval) ?? 0

extension NSUserDefaults {
    
    static var sharedUserDefaults: NSUserDefaults? {
        return NSUserDefaults(suiteName: "group.com.ravenpod.wraplive")
    }
    
    subscript(key: String) -> AnyObject? {
        get {
            return objectForKey(key)
        }
        set(newValue) {
            setObject(newValue, forKey: key)
            enqueueSynchronize()
        }
    }
    
    func enqueueSynchronize() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(NSUserDefaults.synchronize), object: nil)
        self.performSelector(#selector(NSUserDefaults.synchronize), withObject: nil, afterDelay: 0)
    }

    var serverTimeDifference : NSTimeInterval {
        set {
            if (_difference != newValue) {
                _difference = newValue
            }
            self["server_time_difference"] = newValue
        }
        get {
            return _difference
        }
    }
}

