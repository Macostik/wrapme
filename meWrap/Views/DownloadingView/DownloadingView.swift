//
//  DownloadingView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/15/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import Alamofire
import SnapKit

class DownloadingView: UIView {
    
    @IBOutlet weak var progressBar: ProgressBar!
    
    @IBOutlet weak var downloadingMediaLabel: UILabel!
    
    weak var task: Alamofire.Request?
    
    weak var candy: Candy?
    
    class func downloadCandy(candy: Candy?, success: UIImage -> Void, failure: FailureBlock?) {
        if let candy = candy {
            if let error = candy.updateError() {
                failure?(error)
            } else if let url = candy.asset?.original {
                if let cachedImage = cachedImage(url) {
                    success(cachedImage)
                } else {
                    let view: DownloadingView! = loadFromNib("DownloadingView")
                    view.downloadCandy(candy, success:success, failure:failure)
                }
            } else {
                failure?(nil)
            }
        } else {
            failure?(nil)
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
        task = Alamofire.request(.GET, url).progress({ [weak self] (_, sent, total) in
            self?.progressBar.setProgress(CGFloat(sent / total), animated: true)
        }).responseData(completionHandler: { [weak self] response in
            if let data = response.data, let image = UIImage(data: data) {
                ImageCache.defaultCache.setImageData(data, uid: uid)
                InMemoryImageCache.instance[uid] = image
                success(image)
            } else {
                failure?(response.result.error)
            }
            self?.dismiss()
        })
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