//
//  Asset.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class Asset: Archive {
    var original: String?
    var large: String?
    var medium: String?
    var small: String?
    var justUploaded = false
    var type: MediaType = .Photo
    
    override class func archivableProperties() -> Set<String> {
        return ["type","original","large","medium","small"]
    }
    
    override var description: String {
        return "asset:\noriginal: \(original)\nlarge: \(large)\nmedium: \(medium)\nsmall: \(small)"
    }
    
    convenience init(json: NSData) throws {
        self.init()
        let data = try NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions())
        for property in self.dynamicType.archivableProperties() {
            setValue(data[property], forKey: property)
        }
    }
    
    func cacheForAsset(asset: Asset) {
        let cache = WLImageCache.defaultCache()
        if let original = original where original.hasSuffix("mp4") {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(original)
            } catch {
            }
        } else {
            cache.setImageAtPath(original, withUrl: asset.original)
        }
        cache.setImageAtPath(large, withUrl: asset.large)
        cache.setImageAtPath(medium, withUrl: asset.medium)
        cache.setImageAtPath(small, withUrl: asset.small)
    }
    
    func JSONValue() -> NSData? {
        var dictionary = Dictionary<String, AnyObject>()
        for property in self.dynamicType.archivableProperties() {
            if let value = valueForKey(property) {
                dictionary[property] = value
            }
        }
        do {
            return try NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions())
        } catch {
            return nil
        }
    }
    
    func fetch(completionHandler: (Void -> Void)?) {
        guard let completionHandler = completionHandler else {
            WLImageFetcher.defaultFetcher().enqueueImageWithUrl(small)
            WLImageFetcher.defaultFetcher().enqueueImageWithUrl(medium)
            WLImageFetcher.defaultFetcher().enqueueImageWithUrl(large)
            return
        }
        
        var urls = Set<String>()
        
        if let small = small {
            urls.insert(small)
        }
        
        if let medium = medium {
            urls.insert(medium)
        }
        
        if let large = large {
            urls.insert(large)
        }
        
        if urls.count > 0 {
            var fetched = 0
            for url in urls {
                WLBlockImageFetching(url: url).enqueue({ (image) -> Void in
                    fetched++;
                    if urls.count == fetched {
                        completionHandler()
                    }
                    }, failure: { (error) -> Void in
                        fetched++;
                        if urls.count == fetched {
                            completionHandler()
                        }
                })
            }
        } else {
            completionHandler()
        }
    }
}

class AssetTransformer: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        return (value as? Asset)?.JSONValue()
    }
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        if let data = value as? NSData {
            do {
                return try Asset(json: data)
            } catch {
                return Asset.unarchive(data)
            }
        } else {
            return nil
        }
        
    }
}
