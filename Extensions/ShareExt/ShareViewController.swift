//
//  ShareViewController.swift
//  ShareExt
//
//  Created by Yura Granchenko on 02/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

class ShareViewController: UIViewController {
    
    var manager = NSFileManager.defaultManager()
    
    lazy var url: NSURL = {
        if var url = self.manager.containerURLForSecurityApplicationGroupIdentifier("group.com.ravenpod.wraplive") {
            url = url.URLByAppendingPathComponent("ShareExtension/")
            return url
        }
        return NSURL()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = try? manager.removeItemAtURL(url)
        _ = try? manager.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else { return }
        guard let attachments = item.attachments as? [NSItemProvider] where !attachments.isEmpty else { return }
        Dispatch.defaultQueue.async({ [weak self]_ in
            do {
                for attachment in attachments {
                    if let item = try attachment.loadItem(), let data = item.data {
                        self?.writeData(data, extensionType: item.type)
                    }
                }
                
                Dispatch.mainQueue.async {
                    let request = ExtensionRequest(action: .PresentShareContent, parameters: [:])
                    if let url = request.serializedURL() {
                        self?.openURL(url)
                        self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                    }
                }
            } catch let error as String {
                Dispatch.mainQueue.async({ _ in
                    let message = String(format:error, Int(Constants.maxVideoRecordedDuration))
                    let alert = UIAlertController(title: "share_video".ls, message: message, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "ok".ls, style: .Default, handler: { _ in
                        self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                    }))
                    self?.presentViewController(alert, animated: true, completion: nil)
                })
            } catch {}
            })
    }
    
    func writeData(data: NSData, extensionType: String) -> Bool? {
        let path = ("\(NSProcessInfo.processInfo().globallyUniqueString)\(extensionType.lowercaseString)")
        let url = self.url.URLByAppendingPathComponent(path)
        return data.writeToURL(url, atomically: true)
    }
}

extension NSItemProvider {
    
    func tryLoadItem(typeIdentifier: String) -> NSSecureCoding? {
        var data: NSSecureCoding?
        let semaphore = dispatch_semaphore_create(0)
        loadItemForTypeIdentifier(typeIdentifier, options: nil) { item, error in
            data = item
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return data
    }
    
    func loadItem() throws -> (type: String, data: NSData?)? {
        
        if let data = tryLoadItem(kUTTypeImage as String) {
            if let url = data as? NSURL {
                let date = url.cteationDate
                return ("_\(Int(date.timestamp)).jpeg", NSData(contentsOfURL: url))
            } else {
                return (".jpeg", data as? NSData)
            }
        } else if let data = tryLoadItem(kUTTypeMovie as String) {
            guard let url = data as? NSURL else { return nil }
            let date = url.cteationDate
            let asset = AVURLAsset(URL: url)
            if CMTimeGetSeconds(asset.duration) >= Constants.maxVideoRecordedDuration + 1.0 {
                throw "formatted_upload_video_duration_limit".ls
            } else {
                return ("_\(Int(date.timestamp)).\(url.pathExtension ?? "")",  NSData(contentsOfURL: url))
            }
        } else if let data = tryLoadItem(kUTTypeText as String) {
            return (".txt", String(data).dataUsingEncoding(NSUTF8StringEncoding))
        } else if let data = tryLoadItem(kUTTypeURL as String) {
            return (".txt", String(data).dataUsingEncoding(NSUTF8StringEncoding))
        } else {
            return nil
        }
    }
}

extension ShareViewController {
    
    func openURL(url: NSURL) {
        sharedApplication()?.performSelector(#selector(self.openURL(_:)), withObject: url)
    }
    
    func sharedApplication() -> UIApplication? {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application
            }
            responder = responder?.nextResponder()
        }
        return nil
    }
}

extension String: ErrorType {}

extension NSURL {
    
    var cteationDate: NSDate {
        return (try? resourceValuesForKeys([NSURLCreationDateKey]))?[NSURLCreationDateKey] as? NSDate ?? NSDate()
    }
}
