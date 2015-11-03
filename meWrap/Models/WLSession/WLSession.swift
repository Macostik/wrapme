//
//  WLSession.swift
//  meWrap
//
//  Created by Yura Granchenko on 03/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

let WLSessionServerTimeDifference = "WLServerTimeDifference"
var difference : NSTimeInterval = 0
var token: dispatch_once_t = 0
var sharedInstance:  NSUserDefaults?

extension NSUserDefaults {
    
    class func appGroupUserDefaults () -> NSUserDefaults {
        if (sharedInstance == nil) {
            sharedInstance = NSUserDefaults(suiteName:"group.com.ravenpod.wraplive");
        }
        return sharedInstance!
    }

    var serverTimeDifference : NSTimeInterval {
        set {
                if (difference != newValue) {
                difference = newValue
            }
            NSUserDefaults.appGroupUserDefaults().setDouble(newValue, forKey: WLSessionServerTimeDifference)
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "synchronize", object: nil)
            NSUserDefaults.appGroupUserDefaults().performSelector("synchronize")
        }
        get {
                dispatch_once(&token) {
                difference = NSUserDefaults.appGroupUserDefaults().doubleForKey(WLSessionServerTimeDifference)
            }
            return difference
        }
    }
}

