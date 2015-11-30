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
        metrics.uri = NSUserDefaults.standardUserDefaults().imageURI
        metrics.originalKey = WLURLOriginalKey
        metrics.largeKey = WLURLLargeKey
        metrics.mediumKey = WLURLMediumSQKey
        metrics.smallKey = WLURLSmallSQKey
        return metrics
        }()
    
    static var imageMetricsForPad: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().imageURI
        metrics.originalKey = WLURLOriginalKey
        metrics.largeKey = WLURLXLargeKey
        metrics.mediumKey = WLURLLargeKey
        metrics.smallKey = WLURLMediumSQKey
        return metrics
        }()
    
    static var videoMetricsForPhone: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().videoURI
        metrics.originalKey = WLURLOriginalKey
        metrics.largeKey = WLURLLargeKey
        metrics.mediumKey = WLURLMediumSQKey
        metrics.smallKey = WLURLSmallSQKey
        return metrics
        }()
    
    static var videoMetricsForPad: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().videoURI
        metrics.originalKey = WLURLOriginalKey
        metrics.largeKey = WLURLXLargeKey
        metrics.mediumKey = WLURLLargeKey
        metrics.smallKey = WLURLMediumSQKey
        return metrics
        }()
    
    static var avatarMetrics: AssetMetrics = {
        var metrics = AssetMetrics()
        metrics.uri = NSUserDefaults.standardUserDefaults().avatarURI
        metrics.originalKey = WLURLLargeKey
        metrics.largeKey = WLURLLargeKey
        metrics.mediumKey = WLURLMediumKey
        metrics.smallKey = WLURLSmallKey
        return metrics
        }()
}

extension Asset {
    
    func edit(dictionary: [String : String], metrics: AssetMetrics) -> Asset {
        
        var original: String? = self.original
        var large: String? = self.large
        var medium: String? = self.medium
        var small: String? = self.small
        
        guard let uri = metrics.uri else {
            return self
        }
        
        var changed = false
        
        if let originalKey = metrics.originalKey {
            original = parse(originalKey, dictionary: dictionary, uri: uri, current: original)
            if original != self.original {
                changed = true
            }
        }
        
        if let largeKey = metrics.largeKey {
            large = parse(largeKey, dictionary: dictionary, uri: uri, current: large)
            if large != self.large {
                changed = true
            }
        }
        
        if let mediumKey = metrics.mediumKey {
            medium = parse(mediumKey, dictionary: dictionary, uri: uri, current: medium)
            if medium != self.medium {
                changed = true
            }
        }
        
        if let smallKey = metrics.smallKey {
            small = parse(smallKey, dictionary: dictionary, uri: uri, current: small)
            if small != self.small {
                changed = true
            }
        }
        
        if changed {
            let asset = Asset()
            asset.type = self.type
            asset.original = original
            asset.large = large
            asset.medium = medium
            asset.small = small
            return asset
        }
        
        return self
    }
    
    private func parse(key: String?, dictionary: [String : String], uri: String, current: String?) -> String? {
        if let key = key, let url = dictionary[key] where !url.isEmpty {
            return prepend(url: url, uri: uri)
        } else {
            return current
        }
    }
    
    func prepend(url url: String, uri: String) -> String? {
        if url.hasPrefix("http") {
            return url
        }
        return uri.stringByAppendingString(url)
    }
    
    func cacheForAsset(asset: Asset) {
        do {
            let cache = ImageCache.defaultCache
            let manager = NSFileManager.defaultManager()
            if let original = original where original.hasSuffix("mp4") {
                try manager.removeItemAtPath(original)
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
            if let original = original {
                try manager.removeItemAtPath(original)
            }
            if let large = large {
                try manager.removeItemAtPath(large)
            }
            if let medium = medium {
                try manager.removeItemAtPath(medium)
            }
            if let small = small {
                try manager.removeItemAtPath(small)
            }
        } catch {
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
                BlockImageFetching.enqueue(url, success: { (image) -> Void in
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
