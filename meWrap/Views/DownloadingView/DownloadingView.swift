//
//  DownloadingView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/15/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import AFNetworking
import SnapKit

class DownloadingView: UIView {
    
    @IBOutlet weak var progressBar: ProgressBar!
    
    @IBOutlet weak var downloadingMediaLabel: UILabel!
    
    weak var task: NSURLSessionDataTask?
    
    weak var candy: Candy?
    
    class func downloadCandy(candy: Candy, success: UIImage -> Void, failure: FailureBlock?) {
        guard let url = candy.asset?.original else {
            failure?(nil)
            return
        }
        if let cachedImage = cachedImage(url) {
            success(cachedImage)
        } else {
            let view: DownloadingView! = loadFromNib("DownloadingView")
            view.downloadCandy(candy, success:success, failure:failure)
        }
    }
    
    private class func cachedImage(url: String) -> UIImage? {
        let uid = ImageCache.uidFromURL(url)
        if ImageCache.defaultCache.contains(uid) {
            return ImageCache.defaultCache.read(uid)
        } else if url.isExistingFilePath {
            var image = InMemoryImageCache.instance[url]
            if image == nil {
                image = UIImage(contentsOfFile:url)
                InMemoryImageCache.instance[url] = image
            }
            return image
        } else {
            return nil
        }
    }
    
    private func downloadCandy(candy: Candy, success: UIImage -> Void, failure: FailureBlock?) {
        Candy.notifier().addReceiver(self)
        let view = UIWindow.mainWindow
        frame = view.frame
        self.candy = candy
        view.addSubview(self)
        snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        backgroundColor = UIColor(white:0, alpha:0.8)
        alpha = 0.0
        UIView.animateWithDuration(0.5) {
            self.alpha = 1.0
        }
        download(success, failure:failure)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        cancel()
    }
    
    private func  cancel() {
        candy = nil
        task?.cancel()
        dismiss()
    }
    
    private func dismiss() {
        UIView.animateWithDuration(0.5, animations: {
            self.alpha = 0.0
            }, completion: { _ in
                self.removeFromSuperview()
        })
    }
    
    private func download(success: UIImage -> Void,  failure: FailureBlock?) {
        guard let url = candy?.asset?.original else {
            failure?(nil)
            return
        }
        let uid = ImageCache.uidFromURL(url)
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let manager = AFHTTPSessionManager(sessionConfiguration:configuration)
        manager.responseSerializer = AFImageResponseSerializer()
        manager.securityPolicy.allowInvalidCertificates = true
        manager.securityPolicy.validatesDomainName = false
        task = manager.GET(url, parameters:nil, progress:progressBar.downloadProgress(), success: { [weak self] task, responseObject in
            if let image = responseObject as? UIImage {
                ImageCache.defaultCache.write(image, uid:uid)
                success(image)
            } else {
                failure?(nil)
            }
            self?.dismiss()
            }, failure: { [weak self] task, error in
                if (error.code != NSURLErrorCancelled) { failure?(error) }
                self?.dismiss()
            })
        task?.resume()
    }
}

extension DownloadingView: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        cancel()
    }
    
    func notifier(notifier: EntryNotifier, willDeleteContainer container: Entry) {
        cancel()
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return candy == entry;
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnContainer container: Entry) -> Bool {
        return candy?.wrap == container
    }
}