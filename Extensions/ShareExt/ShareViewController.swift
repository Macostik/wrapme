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
    
    lazy var manager = NSFileManager.defaultManager()
    
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
        
        let items = extensionContext?.inputItems
        if let items = items where !items.isEmpty {
            guard let item = items[0] as? NSExtensionItem else { return }
            if let attachments = item.attachments {
                if !attachments.isEmpty {
                    Dispatch.defaultQueue.async({ [weak self]_ in
                        for attachment in attachments {
                            if let itemProvider = attachment as? NSItemProvider {
                                if let item = itemProvider.loadItemForTypeIdentifier() {
                                    guard let data = item.data else {
                                        Dispatch.mainQueue.async({ _ in
                                            let message = String(format:item.type, Int(Constants.maxVideoRecordedDuration))
                                            let alert = UIAlertController(title: "share_video".ls, message: message, preferredStyle: .Alert)
                                            let okAction = UIAlertAction(title: "ok".ls, style: .Default, handler: { _ in
                                                self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                                            })
                                            alert.addAction(okAction)
                                            self?.presentViewController(alert, animated: true, completion: nil)
                                        })
                                        return
                                    }
                                   self?.writeData(data, extensionType: item.type)
                                }
                            }
                        }
                        Dispatch.mainQueue.async({ _ in
                            let request = ExtensionRequest(action: .PresentShareContent, parameters: [:])
                            if let url = request.serializedURL() {
                                self?.openURL(url)
                                self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                            }
                        })
                        })
                }
            }
        }
    }
    
    func writeData(data: NSData, extensionType: String) -> Bool? {
        let path = ("\(NSProcessInfo.processInfo().globallyUniqueString)\(extensionType)")
        let url = self.url.URLByAppendingPathComponent(path)
        return data.writeToURL(url, atomically: true)
    }
}

extension NSItemProvider {
    func loadItemForTypeIdentifier() -> (type: String, data: NSData?)? {
        var data: (String, NSData?)?
        let semaphore = dispatch_semaphore_create(0)
        guard let typeIdentifier = registeredTypeIdentifiers.first as? String else { return nil }
        loadItemForTypeIdentifier(typeIdentifier, options: nil) { item, _ in
            switch typeIdentifier {
            case String(kUTTypeImage), String(kUTTypeJPEG), String(kUTTypeTIFF),
                 String(kUTTypeGIF), String(kUTTypePNG), String(kUTTypeBMP), String(kUTTypeScalableVectorGraphics):
                if let url = item as? NSURL {
                    let date = url.resource(NSURLContentModificationDateKey) as? NSDate ?? NSDate()
                    let timeIntervalSince1970 = Int(date.timeIntervalSince1970)
                    if let imageData = NSData(contentsOfURL: url) {
                        data = ("_\(timeIntervalSince1970).jpeg", imageData)
                    }
                } else if let imageData = item as? NSData {
                    data = (".jpeg", imageData)
                }
                break
            case String(kUTTypeQuickTimeMovie), String(kUTTypeMPEG4):
                guard let url = item as? NSURL else { return }
                let date = url.resource(NSURLCreationDateKey) as? NSDate ?? NSDate()
                let timeIntervalSince1970 = Int(date.timeIntervalSince1970)
                let isMov = typeIdentifier == String(kUTTypeQuickTimeMovie)
                let asset = isMov ? AVAsset(URL: NSURL(fileURLWithPath: url.path!)) : AVAsset(URL: url)
                if CMTimeGetSeconds(asset.duration) >= Constants.maxVideoRecordedDuration + 1.0 {
                    data = ("formatted_upload_video_duration_limit".ls, nil)
                } else if let shareData = NSData(contentsOfURL: url)  {
                    data = (isMov ? "_\(timeIntervalSince1970).mov" : "_\(timeIntervalSince1970).mp4", shareData)
                }
                break
            case String(kUTTypeURL), String(kUTTypePlainText):
                guard let item = item else { return }
                if let shareData = String(item).dataUsingEncoding(NSUTF8StringEncoding) {
                    data = (".txt", shareData)
                    break
                }
            default:
                break
            }
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return data
    }
}

extension ShareViewController {
    func openURL(url: NSURL) -> Bool {
        do {
            let application = try self.sharedApplication()
            return application.performSelector(#selector(ShareViewController.openURL(_:)), withObject: url) != nil
        }
        catch {
            return false
        }
    }
    
    func sharedApplication() throws -> UIApplication {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application
            }
            responder = responder?.nextResponder()
        }
        throw NSError(domain: "ShareExtension", code: 1, userInfo: nil)
    }
}

extension NSURL {
    func resource(key: String) -> AnyObject? {
        return (try? resourceValuesForKeys([key]))?[key]
    }
}
