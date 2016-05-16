//
//  AssetMetrics.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

class AssetURI {
    private let key: String
    var defaultValue: String
    var remoteValue: String? {
        willSet {
            NSUserDefaults.standardUserDefaults()[key] = newValue
        }
    }
    var value: String {
        return remoteValue ?? defaultValue
    }
    init (key: String, defaultValue: String) {
        self.key = key
        self.defaultValue = defaultValue
        self.remoteValue = NSUserDefaults.standardUserDefaults()[key] as? String
    }
    static let imageURI = AssetURI(key: "imageURI", defaultValue: Environment.current.defaultImageURI)
    static let videoURI = AssetURI(key: "videoURI", defaultValue: Environment.current.defaultVideoURI)
    static let avatarURI = AssetURI(key: "avatarURI", defaultValue: Environment.current.defaultAvatarURI)
    static let mediaCommentURI = AssetURI(key: "mediaCommentURI", defaultValue: Environment.current.defaultMediaCommentURI)
}

struct AssetMetrics {
    
    var uri: AssetURI
    var original: String
    var large: String
    var medium: String
    var small: String
    
    static var imageMetrics: AssetMetrics = {
        if UI_USER_INTERFACE_IDIOM() == .Pad {
            return AssetMetrics(uri: AssetURI.imageURI,
                                original: Keys.URL.Original,
                                large: Keys.URL.XLarge,
                                medium: Keys.URL.Large,
                                small: Keys.URL.MediumSQ)
        } else {
            return AssetMetrics(uri: AssetURI.imageURI,
                                original: Keys.URL.Original,
                                large: Keys.URL.Large,
                                medium: Keys.URL.MediumSQ,
                                small: Keys.URL.SmallSQ)
        }
    }()
    
    static var videoMetrics: AssetMetrics = {
        var metrics = imageMetrics
        metrics.uri = AssetURI.videoURI
        return metrics
    }()
    
    static var avatarMetrics = AssetMetrics(uri: AssetURI.avatarURI,
                                            original: Keys.URL.Large,
                                            large: Keys.URL.Large,
                                            medium: Keys.URL.Medium,
                                            small: Keys.URL.Small)
    
    static var mediaCommentMetrics = AssetMetrics(uri: AssetURI.mediaCommentURI,
                                            original: Keys.URL.Original,
                                            large: Keys.URL.Large,
                                            medium: Keys.URL.MediumSQ,
                                            small: Keys.URL.SmallSQ)
}

extension Asset {
    
    func editCandyAsset(dictionary: [String : AnyObject], mediaType: MediaType) -> Asset {
        guard let urls = dictionary[Keys.MediaURLs] as? [String : String] else { return self }
        let metrics = mediaType == .Video ? AssetMetrics.videoMetrics : AssetMetrics.imageMetrics
        return edit(urls, metrics: metrics, type: mediaType)
    }
    
    func edit(urls: [String : String], metrics: AssetMetrics, type: MediaType) -> Asset {
        let uri = metrics.uri.value
        let asset = Asset()
        asset.type = type
        asset.original = urls[metrics.original]?.prepend(uri) ?? self.original
        asset.large = urls[metrics.large]?.prepend(uri) ?? self.large
        asset.medium = urls[metrics.medium]?.prepend(uri) ?? self.medium
        asset.small = urls[metrics.small]?.prepend(uri) ?? self.small
        return asset
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
        return isEmpty || hasPrefix("http") ? self : uri.stringByAppendingString(self)
    }
}
