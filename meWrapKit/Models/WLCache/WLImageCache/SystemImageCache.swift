//
//  SystemImageCache.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class SystemImageCache: NSCache {
    private static var _instance = SystemImageCache()
    class func instance() -> SystemImageCache {
        return _instance
    }
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: nil) {[weak self] _ -> Void in
            self?.removeAllObjects()
        }
    }
    
    subscript(key: String) -> UIImage? {
        get {
            return objectForKey(key) as? UIImage
        }
        set(newValue) {
            if let image = newValue {
                setObject(image, forKey: key)
            } else {
                removeObjectForKey(key)
            }
        }
    }

}