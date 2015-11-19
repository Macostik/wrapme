//
//  ImageFetcher.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

@objc protocol ImageFetching: Notifying {
    
    optional func fetcherTargetUrl(fetcher: ImageFetcher) -> String?
    
    optional func fetcher(fetcher: ImageFetcher, didFinishWithImage image: UIImage, cached: Bool)
    
    optional func fetcher(fetcher: ImageFetcher, didFailWithError error: NSError)
}

class ImageFetcher: Notifier {
    
    private var urls = Set<String>()
    
    private static var _defaultFetcher = ImageFetcher()
    class func defaultFetcher() -> ImageFetcher {
        return _defaultFetcher
    }
    
    func enqueue(url: String?) -> Void {
        guard let url = url where !url.isEmpty else {
            return
        }
        guard !urls.contains(url) else {
            return
        }
        urls.insert(url)
                
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            var image: UIImage?
            if WLImageCache.defaultCache().containsImageWithUrl(url) {
                WLImageCache.defaultCache().imageWithUrl(url, completion: self.imageLoaded)
            } else if url.isExistingFilePath {
                image = self.imageAtPath(url)
            } else {
                image = self.imageAtURL(url)
            }
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.notify({ (receiver) -> Void in
                    
                })
            }
        }
        
        
    }
    
    func enqueue(url: String, receiver: AnyObject?) {
        addReceiver(receiver)
        enqueue(url)
    }
    
    private func imageAtPath(path: String) -> UIImage? {
        if let image = SystemImageCache.instance().imageWithIdentifier(path) {
            return image
        } else if let data = NSData(contentsOfFile: path), let image = UIImage(data: data) {
            SystemImageCache.instance().setImage(image, withIdentifier: path)
            return image
        } else {
            return nil
        }
    }
    
    private func imageAtURL(url: String) -> UIImage? {
        if let _url = url.URL, let data = NSData(contentsOfURL: _url), let image = UIImage(data: data) {
            WLImageCache.defaultCache().setImage(image, withUrl: url)
            return image
        } else {
            return nil
        }
    }
    
}