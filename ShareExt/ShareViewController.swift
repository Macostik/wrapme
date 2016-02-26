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
            guard let path = self?.writeData($0, type: $1) else { return }
            let request = ExtensionRequest(action: "presentShareContent", parameters: ["path":path])
            if let url = request.serializedURL() {
                self?.openURL(url)
            }
            })
    }
    
    func writeData(data: NSData, type: String) -> String? {
        var outputPath = NSHomeDirectory() + "/Documents/ShareExtension/"
        let manager = NSFileManager.defaultManager()
        _ = try? manager.removeItemAtPath(outputPath)
        _ = try? manager.createDirectoryAtPath(outputPath, withIntermediateDirectories: true, attributes: nil)
        outputPath = outputPath + ("\(NSProcessInfo.processInfo().globallyUniqueString)\(type)")
        guard data.writeToFile(outputPath, atomically: true) else { return nil }
        return outputPath
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
                    shareDataBlock(shareData, "image")
                }
            }
        } else if hasItemConformingToTypeIdentifier(String(kUTTypeURL)) == true {
            loadItemForTypeIdentifier(String(kUTTypeURL), options: nil) { (item, error) -> Void in
                if error == nil {
                    if let item = item as? String {
                        if let shareData = item.dataUsingEncoding(NSUTF8StringEncoding) {
                            shareDataBlock(shareData, "text")
                        }
                    }
                }
            }
        } else if hasItemConformingToTypeIdentifier(String(kUTTypePlainText)) == true {
            loadItemForTypeIdentifier(String(kUTTypePlainText), options: nil) { (item, error) -> Void in
                if error == nil {
                    if let item = item as? String {
                        if let shareData = item.dataUsingEncoding(NSUTF8StringEncoding) {
                            shareDataBlock(shareData, "text")
                        }
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
