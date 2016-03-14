//
//  AssetMetrics.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

class AssetMetrics: NSObject {
    
    var uri: String?
    
    var originalKey: String?
    
    var largeKey: String?
    
    var mediumKey: String?
    
    var smallKey: String?
    
    static var imageMetrics: AssetMetrics {
        if (UI_USER_INTERFACE_IDIOM() == .Pad) {
            return imageMetricsForPad
        } else {
            return imageMetricsForPhone
        }
    }
    
    static var videoMetrics: AssetMetrics {
        if (UI_USER_INTERFACE_IDIOM() == .Pad) {
            return videoMetricsForPad
        } else {
            return videoMetricsForPhone
        }
    }
    
    static var imageMetricsForPhone: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().imageURI ?? Environment.current.defaultImageURI
        metrics.originalKey = Keys.URL.Original
        metrics.largeKey = Keys.URL.Large
        metrics.mediumKey = Keys.URL.MediumSQ
        metrics.smallKey = Keys.URL.SmallSQ
        return metrics
        }()
    
    static var imageMetricsForPad: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().imageURI ?? Environment.current.defaultImageURI
        metrics.originalKey = Keys.URL.Original
        metrics.largeKey = Keys.URL.XLarge
        metrics.mediumKey = Keys.URL.Large
        metrics.smallKey = Keys.URL.MediumSQ
        return metrics
        }()
    
    static var videoMetricsForPhone: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().videoURI ?? Environment.current.defaultVideoURI
        metrics.originalKey = Keys.URL.Original
        metrics.largeKey = Keys.URL.Large
        metrics.mediumKey = Keys.URL.MediumSQ
        metrics.smallKey = Keys.URL.SmallSQ
        return metrics
        }()
    
    static var videoMetricsForPad: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().videoURI ?? Environment.current.defaultVideoURI
        metrics.originalKey = Keys.URL.Original
        metrics.largeKey = Keys.URL.XLarge
        metrics.mediumKey = Keys.URL.Large
        metrics.smallKey = Keys.URL.MediumSQ
        return metrics
        }()
    
    static var avatarMetrics: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().avatarURI ?? Environment.current.defaultAvatarURI
        metrics.originalKey = Keys.URL.Large
        metrics.largeKey = Keys.URL.Large
        metrics.smallKey = Keys.URL.Small
        return metrics
        }()
}

extension Asset {
    
    func editCandyAsset(dictionary: [String : AnyObject], mediaType: MediaType) -> Asset {
        guard let urls = dictionary[Keys.MediaURLs] as? [String : String] else { return self }
        switch mediaType {
        case .Photo: return edit(urls, metrics: AssetMetrics.imageMetrics)
        case .Video: return edit(urls, metrics: AssetMetrics.videoMetrics)
        }
    }
    
    func edit(dictionary: [String : String], metrics: AssetMetrics) -> Asset {
        
        guard let uri = metrics.uri else {
            return self
        }
        
        let original = parse(metrics.originalKey, dictionary: dictionary, uri: uri, current: self.original)
        let large = parse(metrics.largeKey, dictionary: dictionary, uri: uri, current: self.large)
        let medium = parse(metrics.mediumKey, dictionary: dictionary, uri: uri, current: self.medium)
        let small = parse(metrics.smallKey, dictionary: dictionary, uri: uri, current: self.small)
        
        if original.changed || large.changed || medium.changed || small.changed {
            let asset = Asset()
            asset.type = self.type
            asset.original = original.url
            asset.large = large.url
            asset.medium = medium.url
            asset.small = small.url
            return asset
        }
        
        return self
    }
    
    private func parse(key: String?, dictionary: [String : String], uri: String, current: String?) -> (url: String?, changed: Bool) {
        if let key = key, let url = dictionary[key] where !url.isEmpty {
            if let url = prepend(url: url, uri: uri) where url != current {
                return (url, true)
            } else {
                return (current, false)
            }
        } else {
            return (current, false)
        }
    }
    
    func prepend(url url: String, uri: String) -> String? {
        return url.hasPrefix("http") ? url : uri.stringByAppendingString(url)
    }
    
    func cacheForAsset(asset: Asset) {
        let cache = ImageCache.defaultCache
        let manager = NSFileManager.defaultManager()
        if let original = original where original.hasSuffix("mp4") {
            
            if let _original = asset.original {
                let path = ImageCache.defaultCache.getPath(ImageCache.uidFromURL(_original)) + ".mp4"
                _ = try? manager.moveItemAtPath(original, toPath: path)
            } else {
                asset.original = original
            }
        } else if let from = original, let to = asset.original {
            cache.setImageAtPath(from, withURL: to)
        }
        if let from = large, let to = asset.large {
            cache.setImageAtPath(from, withURL: to)
        }
        if let from = medium, let to = asset.medium {
            cache.setImageAtPath(from, withURL: to)
        }
        if let from = small, let to = asset.small {
            cache.setImageAtPath(from, withURL: to)
        }
        if let url = original {
            _ = try? manager.removeItemAtPath(url)
            cache.uids.remove(ImageCache.uidFromURL(url))
        }
        if let url = large {
            _ = try? manager.removeItemAtPath(url)
            cache.uids.remove(ImageCache.uidFromURL(url))
        }
        if let url = medium {
            _ = try? manager.removeItemAtPath(url)
            cache.uids.remove(ImageCache.uidFromURL(url))
        }
        if let url = small {
            _ = try? manager.removeItemAtPath(url)
            cache.uids.remove(ImageCache.uidFromURL(url))
        }
    }
    
    func fetch(completionHandler: (Void -> Void)?) {
        guard let completionHandler = completionHandler else {
            ImageFetcher.defaultFetcher.enqueue(small, receiver: nil)
            ImageFetcher.defaultFetcher.enqueue(medium, receiver: nil)
            ImageFetcher.defaultFetcher.enqueue(large, receiver: nil)
            return
        }
        
        var urls = Set<String>()
        
        if let small = small { urls.insert(small) }
        if let medium = medium { urls.insert(medium) }
        if let large = large { urls.insert(large) }
        
        if urls.count > 0 {
            var fetched = 0
            for url in urls {
                BlockImageFetching.enqueue(url, success: { (image) -> Void in
                    fetched++
                    if urls.count == fetched {
                        completionHandler()
                    }
                    }, failure: { (error) -> Void in
                        fetched++
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
