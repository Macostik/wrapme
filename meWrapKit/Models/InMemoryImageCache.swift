//
//  InMemoryImageCache.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/1/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class InMemoryImageCache: NSCache {
    
    static var instance = InMemoryImageCache()
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserverForName("UIApplicationDidReceiveMemoryWarningNotification", object: nil, queue: nil) {[weak self] _ -> Void in
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