//
//  ImageFetcher.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import Alamofire

protocol ImageFetching: class {
    func fetcherTargetUrl(fetcher: ImageFetcher) -> String?
    func fetcher(fetcher: ImageFetcher, didFinishWithImage image: UIImage, cached: Bool)
    func fetcher(fetcher: ImageFetcher, didFailWithError error: NSError)
}

final class ImageFetcher: Notifier {
    
    private var urls = Set<String>()
    
    static var defaultFetcher = ImageFetcher()
    
    private func notify(url: String, @noescape block: ImageFetching -> Void) {
        urls.remove(url)
        for wrapper in receivers {
            if let receiver = wrapper.receiver as? ImageFetching {
                if let targetURL = receiver.fetcherTargetUrl(self) where targetURL == url {
                    block(receiver)
                    receivers.remove(wrapper)
                }
            }
        }
    }
    
    func enqueue(url: String?, receiver: NSObject?) -> Void {
        
        guard let url = url where !url.isEmpty else { return }
        
        addReceiver(receiver)
        
        guard !urls.contains(url) else { return }
        
        urls.insert(url)
        
        imageAtURL(url) { (image, cached) -> Void in
            if let image = image {
                self.notify(url, block: { $0.fetcher(self, didFinishWithImage: image, cached: cached) })
            } else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
                self.notify(url, block: { $0.fetcher(self, didFailWithError: error) })
            }
        }
    }
    
    private func imageAtURL(url: String, result: (UIImage?, Bool) -> Void) {
        if url.isExistingFilePath {
            imageWithContentsOfFile(url, result: result)
        } else {
            imageWithContentsOfURL(url, result: result)
        }
    }
    
    private func imageWithContentsOfFile(path: String, result: (UIImage?, Bool) -> Void) {
        let uid = (path as NSString).lastPathComponent
        if let image = InMemoryImageCache.instance[uid] {
            result(image, true)
        } else if ImageCache.defaultCache.contains(uid) {
            Dispatch.defaultQueue.fetch({ ImageCache.defaultCache[uid] }, completion: { result($0, false) })
        } else if ImageCache.uploadingCache.contains(uid) {
            Dispatch.defaultQueue.fetch({ ImageCache.uploadingCache[uid] }, completion: { result($0, false) })
        } else if let image = InMemoryImageCache.instance[path] {
            result(image, true)
        } else {
            Dispatch.defaultQueue.fetch({
                guard let data = NSData(contentsOfFile: path), let image = UIImage(data: data) else { return nil }
                InMemoryImageCache.instance[path] = image
                return image
                }, completion: { result($0, false) })
        }
    }
    
    private func imageWithContentsOfURL(url: String, result: (UIImage?, Bool) -> Void) {
        let uid = ImageCache.uidFromURL(url)
        if let image = InMemoryImageCache.instance[uid] {
            result(image, true)
        } else if ImageCache.defaultCache.contains(uid) {
            Dispatch.defaultQueue.fetch({ ImageCache.defaultCache[uid] }, completion: { result($0, false) })
        } else {
            Alamofire.request(.GET, url).responseData(completionHandler: { response in
                if let data = response.data, let image = UIImage(data: data) {
                    Dispatch.defaultQueue.async({
                        ImageCache.defaultCache.setImageData(data, uid: uid)
                        InMemoryImageCache.instance[uid] = image
                        Dispatch.mainQueue.async({
                            result(image, false)
                        })
                    })
                } else {
                    result(nil, false)
                }
            })
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
    func fetcherTargetUrl(fetcher: ImageFetcher) -> String? { return url }
    
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