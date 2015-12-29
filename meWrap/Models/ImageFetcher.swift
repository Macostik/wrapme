//
//  ImageFetcher.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

@objc protocol ImageFetching {
    
    optional func fetcherTargetUrl(fetcher: ImageFetcher) -> String?
    
    optional func fetcher(fetcher: ImageFetcher, didFinishWithImage image: UIImage, cached: Bool)
    
    optional func fetcher(fetcher: ImageFetcher, didFailWithError error: NSError)
}

class ImageFetcher: Notifier {
    
    private var urls = Set<String>()
    
    static var defaultFetcher = ImageFetcher()
    
    private func broadcast(url: String, block: AnyObject -> Void) {
        urls.remove(url)
        let receivers = self.receivers
        for wrapper in receivers {
            if let receiver = wrapper.receiver as? ImageFetching {
                if let targetURL = receiver.fetcherTargetUrl?(self) where targetURL == url {
                    block(receiver)
                    self.receivers.remove(wrapper)
                }
            }
        }
    }
    
    func enqueue(url: String?, receiver: NSObject?) -> Void {
        
        guard let url = url, let receiver = receiver where !url.isEmpty else {
            return
        }
        
        addReceiver(receiver)
        
        guard !urls.contains(url) else {
            return
        }
        
        urls.insert(url)
        
        let uid = ImageCache.uidFromURL(url)
        if let image = InMemoryImageCache.instance[uid] {
            self.broadcast(url, block: { (receiver) in
                receiver.fetcher?(self, didFinishWithImage: image, cached: true)
            })
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                var image: UIImage?
                var cached = false
                if ImageCache.defaultCache.contains(uid) {
                    image = ImageCache.defaultCache[uid]
                } else if url.isExistingFilePath {
                    let result = self.imageAtPath(url)
                    image = result.image
                    cached = result.cached
                } else {
                    image = self.imageAtURL(url)
                }
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    if let image = image {
                        self.broadcast(url, block: { (receiver) in
                            receiver.fetcher?(self, didFinishWithImage: image, cached: cached)
                        })
                    } else {
                        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
                        self.broadcast(url, block: { (receiver) in
                            receiver.fetcher?(self, didFailWithError: error)
                        })
                    }
                }
            }
        }
    }
    
    private func imageAtPath(path: String) -> (image: UIImage?, cached: Bool) {
        if let image = InMemoryImageCache.instance[path] {
            return (image, true)
        } else if let data = NSData(contentsOfFile: path), let image = UIImage(data: data) {
            InMemoryImageCache.instance[path] = image
            return (image, false)
        } else {
            return (nil, false)
        }
    }
    
    private func imageAtURL(url: String) -> UIImage? {
        if let _url = url.URL, let data = NSData(contentsOfURL: _url), let image = UIImage(data: data) {
            ImageCache.defaultCache.setImage(image, withURL: url)
            return image
        } else {
            return nil
        }
    }
}

class BlockImageFetching: NSObject {
    
    private static var fetchings = Set<BlockImageFetching>()
    private var url: String?
    private var success: (UIImage -> Void)?
    private var failure: (NSError? -> Void)?
    
    class func enqueue(url: String, success: (UIImage -> Void)?, failure: (NSError? -> Void)?) {
        let fetching = BlockImageFetching(url: url)
        fetching.enqueue(success, failure: failure)
    }
    
    init(url: String?) {
        super.init()
        self.url = url
    }
    
    func enqueue(success: (UIImage -> Void)?, failure: (NSError? -> Void)?) {
        BlockImageFetching.fetchings.insert(self)
        self.success = success
        self.failure = failure
        ImageFetcher.defaultFetcher.enqueue(url, receiver: self)
    }
}

extension BlockImageFetching: ImageFetching {
    func fetcherTargetUrl(fetcher: ImageFetcher) -> String? {
        return url
    }
    
    func fetcher(fetcher: ImageFetcher, didFinishWithImage image: UIImage, cached: Bool) {
        success?(image)
        success = nil
        failure = nil
        BlockImageFetching.fetchings.remove(self)
    }
    
    func fetcher(fetcher: ImageFetcher, didFailWithError error: NSError) {
        failure?(error)
        success = nil
        failure = nil
        BlockImageFetching.fetchings.remove(self)
    }
}