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
    
    lazy var url: NSURL = NSURL.shareExtension()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = try? manager.removeItemAtURL(url)
        _ = try? manager.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else { return }
        guard let attachments = item.attachments as? [NSItemProvider] where !attachments.isEmpty else { return }
        Dispatch.defaultQueue.async({
            do {
                
                var items = [[String:String]]()
                var itemType: String = ""
                
                for attachment in attachments {
                    let item = try attachment.loadItem()
                    if case let item_Type = itemType where (item_Type == "photo" || item_Type == "video") && item.type == "text" {
                        break
                    } else if case let item_Type = itemType where item_Type == "text" && (item.type == "photo" || item.type == "video") {
                        break
                    } else {
                        itemType = item.type
                        let fileName = self.writeItem(item)
                        let createdAt = item.createdAt ?? NSDate()
                        items.append(["fileName":fileName,"type":item.type, "createdAt" : String(createdAt.timestamp)])
                    }
                }
                
                Dispatch.mainQueue.async {
                    let request = ExtensionRequest(action: .PresentShareContent, parameters: ["items" : items])
                    if let url = request.serializedURL() {
                        self.openURL(url)
                        self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                    }
                }
            } catch let error as String {
                Dispatch.mainQueue.async({ _ in
                    let message = String(format:error, Int(Constants.maxVideoRecordedDuration))
                    let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "ok".ls, style: .Default, handler: { _ in
                        self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            } catch {}
            })
    }
    
    func writeItem(item: ShareItem) -> String {
        let fileName = ("\(NSProcessInfo.processInfo().globallyUniqueString).\(item.pathExtension.lowercaseString)")
        let url = self.url.URLByAppendingPathComponent(fileName)
        item.data.writeToURL(url, atomically: true)
        return fileName
    }
}

struct ShareItem {
    let data: NSData
    let pathExtension: String
    let type: String
    let createdAt: NSDate?
}

extension NSItemProvider {
    
    func tryLoadItem(type: CFString) -> NSSecureCoding? {
        var data: NSSecureCoding?
        let semaphore = dispatch_semaphore_create(0)
        loadItemForTypeIdentifier(type as String, options: nil) { item, error in
            data = item
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return data
    }
    
    func loadItem() throws -> ShareItem {
        
        if let data = tryLoadItem(kUTTypeImage) {
            if let url = data as? NSURL, let data = NSData(contentsOfURL: url) {
                return ShareItem(data: data, pathExtension: url.pathExtension ?? "", type: "photo", createdAt: url.cteationDate)
            } else if let data = data as? NSData {
                return ShareItem(data: data, pathExtension: "jpg", type: "photo", createdAt: nil)
            } else if let image = data as? UIImage, let data = UIImageJPEGRepresentation(image, 1) {
                return ShareItem(data: data, pathExtension: "jpg", type: "photo", createdAt: nil)
            }
        } else if let url = tryLoadItem(kUTTypeMovie) as? NSURL {
            let asset = AVURLAsset(URL: url)
            if CMTimeGetSeconds(asset.duration) >= Constants.maxVideoRecordedDuration + 1.0 {
                throw "formatted_upload_video_duration_limit".ls
            } else if let data = NSData(contentsOfURL: url) {
                return ShareItem(data: data, pathExtension: url.pathExtension ?? "", type: "video", createdAt: url.cteationDate)
            }
        } else if let data = tryLoadItem(kUTTypeText) ?? tryLoadItem(kUTTypeURL), let textData = String(data).dataUsingEncoding(NSUTF8StringEncoding) {
            return ShareItem(data: textData, pathExtension: "txt", type: "text", createdAt: nil)
        }
        throw "No acceptable content types"
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
