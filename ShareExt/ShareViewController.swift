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
        
        let imageType = kUTTypeImage as String
        let urlType = kUTTypeURL as String
        let textType = kUTTypePlainText as String
        
        if itemProvider?.hasItemConformingToTypeIdentifier(imageType) == true {
            itemProvider?.loadItemForTypeIdentifier(imageType, options: nil) { [weak self] (item, error) -> Void in
                if error == nil {
                    if let url = item as? NSURL {
                        if let imageData = NSData(contentsOfURL: url) {
                            self?.imageToShare = UIImage(data: imageData)
                        }
                    } else if let data = item as? NSData {
                        self?.imageToShare = UIImage(data: data)
                    }
                }
            }
        } else if itemProvider?.hasItemConformingToTypeIdentifier(textType) == true || itemProvider?.hasItemConformingToTypeIdentifier(urlType) == true {
            itemProvider?.loadItemForTypeIdentifier(textType, options: nil) { [weak self] (item, error) -> Void in
                if error == nil {
                    self?.textToShare = String(item)
                }
            }
        }
    }
}