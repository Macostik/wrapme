//
//  AssetMetrics.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

struct AssetMetrics {
    
    var uri: String
    var original: String
    var large: String
    var medium: String
    var small: String
    
    static var imageMetrics: AssetMetrics = {
        if UI_USER_INTERFACE_IDIOM() == .Pad {
            return AssetMetrics(uri: NSUserDefaults.standardUserDefaults().imageURI,
                                original: Keys.URL.Original,
                                large: Keys.URL.XLarge,
                                medium: Keys.URL.Large,
                                small: Keys.URL.MediumSQ)
        } else {
            return AssetMetrics(uri: NSUserDefaults.standardUserDefaults().imageURI,
                                original: Keys.URL.Original,
                                large: Keys.URL.Large,
                                medium: Keys.URL.MediumSQ,
                                small: Keys.URL.SmallSQ)
        }
    }()
    
    static var videoMetrics: AssetMetrics = {
        var metrics = imageMetrics
        metrics.uri = NSUserDefaults.standardUserDefaults().videoURI
        return metrics
    }()
    
    static var avatarMetrics = AssetMetrics(uri: NSUserDefaults.standardUserDefaults().avatarURI,
                                            original: Keys.URL.Large,
                                            large: Keys.URL.Large,
                                            medium: Keys.URL.Medium,
                                            small: Keys.URL.Small)
}

extension Asset {
    
    func editCandyAsset(dictionary: [String : AnyObject], mediaType: MediaType) -> Asset {
        guard let urls = dictionary[Keys.MediaURLs] as? [String : String] else { return self }
        switch mediaType {
        case .Photo: return edit(urls, metrics: AssetMetrics.imageMetrics)
        case .Video: return edit(urls, metrics: AssetMetrics.videoMetrics)
        }
    }
    
    func edit(urls: [String : String], metrics: AssetMetrics) -> Asset {
        let uri = metrics.uri
        let asset = Asset()
        asset.original = urls[metrics.original]?.prepend(uri) ?? self.original
        asset.large = urls[metrics.large]?.prepend(uri) ?? self.large
        asset.medium = urls[metrics.medium]?.prepend(uri) ?? self.medium
        asset.small = urls[metrics.small]?.prepend(uri) ?? self.small
        return self != asset ? asset : self
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
    
    func fetch(completionHandler: (Void -> Void)? = nil) {
        Dispatch.backgroundQueue.async {
            BlockImageFetching.enqueue(self.small)
            BlockImageFetching.enqueue(self.medium)
            BlockImageFetching.enqueue(self.large)
            Dispatch.mainQueue.async(completionHandler)
        }
    }
}

extension String {
    
    func prepend(uri: String) -> String {
        return hasPrefix("http") ? self : uri.stringByAppendingString(self)
    }
}
