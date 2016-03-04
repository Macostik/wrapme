//
//  ShareViewController.swift
//  ShareExt
//
//  Created by Yura Granchenko on 02/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices

class ShareViewController: UIViewController {
    
    var urlSession: NSURLSession?
    
    var imageToShare: UIImage?
    var textToShare: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let items = extensionContext?.inputItems
        var itemProvider: NSItemProvider?
        if let items = items where !items.isEmpty {
            guard let item = items[0] as? NSExtensionItem else { return }
            if let attachments = item.attachments {
                if !attachments.isEmpty {
                    itemProvider = attachments[0] as? NSItemProvider
                }
            }
        }
        
        itemProvider?.loadItemForTypeIdentifier({ [weak self] in
            guard let path = self?.writeData($0, extensionType: $1) else { return }
            let request = ExtensionRequest(action: "presentShareContent", parameters: ["path":path])
            if let url = request.serializedURL() {
                self?.openURL(url)
                self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
            }
            })
    }
    
    func writeData(data: NSData, extensionType: String) -> String? {
        let manager = NSFileManager.defaultManager()
        if var url = manager.containerURLForSecurityApplicationGroupIdentifier("group.com.ravenpod.wraplive") {
            let path = ("\(NSProcessInfo.processInfo().globallyUniqueString)\(extensionType)")
            url = url.URLByAppendingPathComponent("ShareExtension/")
            _ = try? manager.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
            url = url.URLByAppendingPathComponent(path)
            guard data.writeToURL(url, atomically: true) else {
                return nil
            }
            return path
        }
        
        return nil
    }
}

extension NSItemProvider {
    func loadItemForTypeIdentifier(shareDataBlock: (NSData, String) -> Void) {
        if hasItemConformingToTypeIdentifier(String(kUTTypeImage)) == true {
            loadItemForTypeIdentifier(String(kUTTypeImage), options: nil) { (item, error) -> Void in
                var shareData = NSData()
                if error == nil {
                    if let url = item as? NSURL {
                        if let imageData = NSData(contentsOfURL: url) {
                            shareData = imageData
                        }
                    } else if let imageData = item as? NSData {
                        shareData = imageData
                    }
                    shareDataBlock(shareData, ".jpeg")
                }
            }
        } else if hasItemConformingToTypeIdentifier(String(kUTTypeQuickTimeMovie)) == true {
            loadItemForTypeIdentifier(String(kUTTypeQuickTimeMovie), options: nil) { (item, error) -> Void in
                if error == nil, let item = item as? NSURL {
                    if let shareData = item.path!.dataUsingEncoding(NSUTF8StringEncoding) {
                        shareDataBlock(shareData, ".asset")
                    }
                }
            }
        } else if hasItemConformingToTypeIdentifier(String(kUTTypeMovie)) == true {
            loadItemForTypeIdentifier(String(kUTTypeMovie), options: nil) { (item, error) -> Void in
                var shareData = NSData()
                if error == nil {
                    if let url = item as? NSURL {
                        if let imageData = NSData(contentsOfURL: url) {
                            shareData = imageData
                        }
                    } else if let imageData = item as? NSData {
                        shareData = imageData
                    }
                    shareDataBlock(shareData, ".mp4")
                }
            }
        } else if hasItemConformingToTypeIdentifier(String(kUTTypeURL)) == true {
            loadItemForTypeIdentifier(String(kUTTypeURL), options: nil) { (item, error) -> Void in
                if error == nil, let item = item {
                    if let shareData = String(item).dataUsingEncoding(NSUTF8StringEncoding) {
                        shareDataBlock(shareData, ".txt")
                    }
                }
            }
        } else if hasItemConformingToTypeIdentifier(String(kUTTypePlainText)) == true {
            loadItemForTypeIdentifier(String(kUTTypePlainText), options: nil) { (item, error) -> Void in
                if error == nil, let item = item {
                    if let shareData = String(item).dataUsingEncoding(NSUTF8StringEncoding) {
                        shareDataBlock(shareData, ".txt")
                    }
                }
            }
        }
    }
}

extension ShareViewController {
    func openURL(url: NSURL) -> Bool {
        do {
            let application = try self.sharedApplication()
            return application.performSelector("openURL:", withObject: url) != nil
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
