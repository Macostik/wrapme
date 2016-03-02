//
//  NSBundle+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension NSBundle {
    
    func plist(name: String) -> String?  {
        return pathForResource(name, ofType: "plist")
    }
    
    var displayName: String? {
        return objectForInfoDictionaryKey("CFBundleDisplayName") as? String
    }
    
    var buildVersion: String? {
        return objectForInfoDictionaryKey("CFBundleShortVersionString") as? String
    }
    
    var buildNumber: String? {
        return objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String
    }
}

extension NSArray {
    
    class func plist(name: String) -> NSArray? {
        guard let path = NSBundle.mainBundle().plist(name) else { return nil }
        return NSArray(contentsOfFile: path)
    }
}

extension NSDictionary {
    
    class func plist(name: String) -> NSDictionary? {
        guard let path = NSBundle.mainBundle().plist(name) else { return nil }
        return NSDictionary(contentsOfFile: path)
    }
}