//
//  AssetCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Photos

class AssetCell: StreamReusableView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var acceptView: UIView!
    @IBOutlet weak var videoIndicator: UILabel!
    private var requestID: PHImageRequestID?
    
    override func willEnqueue() {
        if let requestID = requestID {
            PHImageManager.defaultManager().cancelImageRequest(requestID)
        }
    }
    
    private static var requestImageOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.synchronous = false
        options.networkAccessAllowed = true
        options.resizeMode = .Fast
        options.deliveryMode = .FastFormat
        return options
    }()
    
    override func setup(entry: AnyObject!) {
        if let asset = entry as? PHAsset {
            let scale = UIScreen.mainScreen().scale
            let thumbnail = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let options = AssetCell.requestImageOptions
            requestID = PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: thumbnail, contentMode: .AspectFill, options: options, resultHandler: {[weak self] (image, info) -> Void in
                self?.imageView.image = image
            })
            videoIndicator.hidden = asset.mediaType != .Video
        }
    }
    
    override var selected: Bool {
        didSet {
            backgroundColor = selected ? UIColor.whiteColor() : UIColor.clearColor()
            acceptView.hidden = !selected
            imageView.alpha = selected ? 0.5 : 1.0
        }
    }
}