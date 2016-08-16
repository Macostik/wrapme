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
    var url: String? { get }
    func didFinishWithImage(image: UIImage, cached: Bool)
    func didFailWithError(error: NSError?)
}

final class ImageFetcher {
    
    private struct ReceiverWrapper {
        weak var receiver: ImageFetching?
    }
    
    private var receivers = [ReceiverWrapper]()
    
    private var urls = Set<String>()
    
    static var defaultFetcher = ImageFetcher()
    
    private func notify(url: String, @noescape block: ImageFetching -> Void) {
        urls.remove(url)
        receivers = receivers.filter({ (wrapper) -> Bool in
            if let receiver = wrapper.receiver where receiver.url == url {
                block(receiver)
                return false
            } else {
                return true
            }
        })
    }
    
    func enqueue(url: String?, receiver: ImageFetching?) -> Void {
        
        guard let url = url where !url.isEmpty else { return }
        
        receivers.append(ReceiverWrapper(receiver: receiver))
        
        guard !urls.contains(url) else { return }
        
        urls.insert(url)
        
        imageAtURL(url) { (image, cached, error) -> Void in
            if let image = image {
                self.notify(url, block: { $0.didFinishWithImage(image, cached: cached) })
            } else {
                self.notify(url, block: { $0.didFailWithError(error) })
            }
        }
    }
    
    private func imageAtURL(url: String, result: (UIImage?, Bool, NSError?) -> Void) {
        if url.isExistingFilePath {
            imageWithContentsOfFile(url, result: result)
        } else {
            imageWithContentsOfURL(url, result: result)
        }
    }
    
    private func imageWithContentsOfFile(path: String, result: (UIImage?, Bool, NSError?) -> Void) {
        let uid = (path as NSString).lastPathComponent
        if let image = InMemoryImageCache.instance[uid] {
            result(image, true, nil)
        } else if ImageCache.defaultCache.contains(uid) {
            Dispatch.defaultQueue.fetch({ ImageCache.defaultCache[uid] }, completion: { result($0, false, nil) })
        } else if ImageCache.uploadingCache.contains(uid) {
            Dispatch.defaultQueue.fetch({ ImageCache.uploadingCache[uid] }, completion: { result($0, false, nil) })
        } else if let image = InMemoryImageCache.instance[path] {
            result(image, true, nil)
        } else {
            Dispatch.defaultQueue.fetch({
                guard let data = NSData(contentsOfFile: path), let image = UIImage(data: data) else { return nil }
                InMemoryImageCache.instance[path] = image
                return image
                }, completion: { result($0, false, nil) })
        }
    }
    
    private func imageWithContentsOfURL(url: String, result: (UIImage?, Bool, NSError?) -> Void) {
        let uid = ImageCache.uidFromURL(url)
        if let image = InMemoryImageCache.instance[uid] {
            result(image, true, nil)
        } else if ImageCache.defaultCache.contains(uid) {
            Dispatch.defaultQueue.fetch({ ImageCache.defaultCache[uid] }, completion: { result($0, false, nil) })
        } else {
            Alamofire.request(.GET, url).responseData(completionHandler: { response in
                if let data = response.data, let image = UIImage(data: data) {
                    Dispatch.defaultQueue.async({
                        ImageCache.defaultCache.setImageData(data, uid: uid)
                        InMemoryImageCache.instance[uid] = image
                        Dispatch.mainQueue.async({
                            result(image, false, nil)
                        })
                    })
                } else {
                    result(nil, false, response.result.error)
                }
            })
        }
    }
}

final class BlockImageFetching: ImageFetching {
    
    private static var fetchings = [BlockImageFetching]()
    internal var url: String?
    private var success: (UIImage -> Void)?
    private var failure: (NSError? -> Void)?
    
    static func enqueue(url: String?, success: (UIImage -> Void)?, failure: (NSError? -> Void)?) {
        let fetching = BlockImageFetching(url: url)
        fetching.enqueue(success, failure: failure)
    }
    
    static func enqueue(url: String?) -> UIImage? {
        guard url != nil else { return nil }
        return Dispatch.sleep({ (awake) in
            Dispatch.mainQueue.async {
                enqueue(url, success: { image in awake(image) }, failure: { _ in awake(nil) })
            }
        })
    }
    
    init(url: String?) {
        self.url = url
    }
    
    func enqueue(success: (UIImage -> Void)?, failure: (NSError? -> Void)?) {
        BlockImageFetching.fetchings.append(self)
        self.success = success
        self.failure = failure
        ImageFetcher.defaultFetcher.enqueue(url, receiver: self)
    }
    
    func didFinishWithImage(image: UIImage, cached: Bool) {
        success?(image)
        success = nil
        failure = nil
        if let index = BlockImageFetching.fetchings.indexOf({ $0 === self }) {
            BlockImageFetching.fetchings.removeAtIndex(index)
        }
    }
    
    func didFailWithError(error: NSError?) {
        failure?(error)
        success = nil
        failure = nil
        if let index = BlockImageFetching.fetchings.indexOf({ $0 === self }) {
            BlockImageFetching.fetchings.removeAtIndex(index)
        }
    }
}