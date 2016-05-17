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
    
    private let progressBar = ProgressBar()
    
    private let messageLabel = Label(preset: .Small, weight: .Light, textColor: UIColor.whiteColor())
    
    weak var task: Alamofire.Request?
    
    var candy: Candy
    
    static func downloadCandy(candy: Candy?, message: String, success: NSURL -> Void, failure: FailureBlock? = nil) {
        if let candy = candy, let url = candy.asset?.original {
            if let cachedImage = candy.isVideo ? cachedVideo(url) : cachedImage(url) {
                success(cachedImage)
            } else {
                let view = DownloadingView(candy: candy, message: message)
                view.download(url, success: success, failure:failure)
            }
        } else {
            failure?(nil)
        }
    }
    
    static func downloadCandyImage(candy: Candy?, success: UIImage -> Void, failure: FailureBlock? = nil) {
        downloadCandy(candy, message: "downloading_photo_for_editing".ls, success: { (url) in
            if let data = NSData(contentsOfURL: url), let image = UIImage(data: data) {
                success(image)
            } else {
                failure?(nil)
            }
            }, failure: failure)
    }
    
    private static func cachedVideo(url: String) -> NSURL? {
        if url.isExistingFilePath {
            return url.fileURL
        } else {
            let path = ImageCache.defaultCache.getPath(ImageCache.uidFromURL(url, ext: "mp4"))
            if path.isExistingFilePath {
                return path.fileURL
            }
        }
        return nil
    }
    
    private static func cachedImage(url: String) -> NSURL? {
        let uid = ImageCache.uidFromURL(url)
        if ImageCache.defaultCache.contains(uid) {
            return NSURL(fileURLWithPath: ImageCache.defaultCache.getPath(uid))
        } else if url.isExistingFilePath {
            return NSURL(fileURLWithPath: url)
        } else {
            return nil
        }
    }
    
    private func download(url: String, success: NSURL -> Void, failure: FailureBlock?) {
        let isVideo = candy.isVideo
        let uid = ImageCache.uidFromURL(url, ext: isVideo ? "mp4" : "jpg")
        let destination = ImageCache.defaultCache.getPath(uid)
        download(url, destination: destination, success: { url in
            ImageCache.defaultCache.uids.insert(uid)
            success(url)
            }, failure: failure)
    }

    required init(candy: Candy, message: String) {
        self.candy = candy
        let view = UIWindow.mainWindow
        super.init(frame: view.frame)
        messageLabel.numberOfLines = 0
        messageLabel.text = message
        Candy.notifier().addReceiver(self)
        view.addSubview(self)
        snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        backgroundColor = UIColor(white:0, alpha:0.8)
        
        let cancelButton = Button(type: .Custom)
        cancelButton.titleLabel?.font = Font.Normal + .Light
        cancelButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        cancelButton.setTitleColor(Color.grayLighter, forState: .Highlighted)
        cancelButton.setTitle("cancel".ls, forState: .Normal)
        cancelButton.addTarget(self, touchUpInside: #selector(self.cancel(_:)))
        add(cancelButton) { (make) in
            make.top.trailing.equalTo(self).inset(32)
        }
        
        let centerView = UIView()
        
        add(centerView) { (make) in
            make.center.equalTo(self)
            make.trailing.lessThanOrEqualTo(self).inset(20)
            make.leading.greaterThanOrEqualTo(self).inset(20)
        }
        
        centerView.add(messageLabel) { (make) in
            make.leading.trailing.top.equalTo(centerView)
        }
        
        progressBar.backgroundColor = UIColor.whiteColor()
        centerView.add(progressBar) { (make) in
            make.top.equalTo(messageLabel.snp_bottom).inset(-20)
            make.centerX.equalTo(centerView)
            make.size.equalTo(CGSize(width: 180, height: 1))
        }
        
        let icon = Label(icon: "a", size: 60, textColor: UIColor.whiteColor())
        
        centerView.add(icon) { (make) in
            make.top.equalTo(progressBar.snp_bottom).inset(-20)
            make.centerX.bottom.equalTo(centerView)
        }
        
        alpha = 0.0
        UIView.animateWithDuration(0.5) {
            self.alpha = 1.0
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func cancel(sender: AnyObject) {
        cancel()
    }
    
    private func  cancel() {
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
    
    private func download(source: String, destination: String, success: NSURL -> Void, failure: FailureBlock?) {
        let downloadURL = NSURL(fileURLWithPath: destination)
        task = Alamofire.download(.GET, source , destination: { _ in return downloadURL })
            .progress { [weak self] (_, sent, total) in
                Dispatch.mainQueue.async({
                    self?.progressBar.setProgress(CGFloat(sent / total), animated: true)
                })
            }.validate(statusCode: 200..<300).response { [weak self] (request, response, data, error) in
                if error != nil {
                    failure?(error)
                } else {
                    success(downloadURL)
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
        return candy.wrap == container
    }
}