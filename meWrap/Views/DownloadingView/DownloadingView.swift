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
    
    lazy var shareFolderUrl: NSURL = {
        if var url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.ravenpod.wraplive") {
            url = url.URLByAppendingPathComponent("ShareExtension/")
            return url
        }
        return NSURL()
    }()
    
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
    
    class func downloadCandyToURL(candy: Candy?, success: NSURL -> Void, failure: FailureBlock?) {
        if let candy = candy {
            let view: DownloadingView! = loadFromNib("DownloadingView")
            view.downloadingMediaLabel.text = "downloading_photo_for_sharing".ls
            view.progressBar.progress = 0.0
            view.downloadCandyToURL(candy, success: success, failure: failure)
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
        setup(candy)
        download(success, failure:failure)
    }
    
    private func downloadCandyToURL(candy: Candy, success: NSURL -> Void, failure: FailureBlock?) {
        setup(candy)
        downloadToURL(success, failure: failure)
    }

    
    private func setup(candy: Candy) {
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
            Dispatch.mainQueue.async({
                self?.progressBar.setProgress(CGFloat(sent / total), animated: true)
            })
        }).validate(statusCode: 200..<300).responseData(completionHandler: { [weak self] response in
            switch response.result {
            case .Success(let data):
                if let image = UIImage(data: data) {
                    ImageCache.defaultCache.setImageData(data, uid: uid)
                    InMemoryImageCache.instance[uid] = image
                    success(image)
                } else {
                    failure?(response.result.error)
                }
            default:
                failure?(response.result.error)
            }
            self?.dismiss()
        })
    }
    
    private func downloadToURL(succes: NSURL -> Void, failure: FailureBlock?) {
        guard let url = candy?.asset?.original else {
            failure?(nil)
            return
        }
        let manager = NSFileManager.defaultManager()
        _ = try? manager.removeItemAtURL(shareFolderUrl)
        _ = try? manager.createDirectoryAtURL(shareFolderUrl, withIntermediateDirectories: true, attributes: nil)
        let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = { _, response in
            return self.shareFolderUrl.URLByAppendingPathComponent(response.suggestedFilename!)
        }
        task = Alamofire.download(.GET, url, destination: destination)
            .progress { [weak self] (_, sent, total) in
                Dispatch.mainQueue.async({
                    self?.progressBar.setProgress(CGFloat(sent / total), animated: true)
                })
            }.validate(statusCode: 200..<300).response { [weak self] (request, response, data, error) in
                if error != nil {
                    failure?(error)
                } else if let url = request?.URL, let response = response {
                    let destination = destination(url, response)
                    succes(destination)
                }
                self?.dismiss()
        }
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