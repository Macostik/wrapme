//
//  EditAssetViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class EditAssetViewController: UIViewController {
    
    @IBOutlet weak var imageView: ImageView!
    
    var asset: MutableAsset?

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.url = asset?.large
    }
}

class EditAssetCell: StreamReusableView {
    
    @IBOutlet weak var imageView: ImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var videoIndicator: UILabel!
    
    override func setup(entry: AnyObject) {
        if let asset = entry as? MutableAsset {
            imageView.url = asset.small
            updateStatus()
            selectionView.hidden = !asset.selected;
            videoIndicator.hidden = asset.type != .Video
        }
    }
    
    func updateStatus() {
        if let asset = entry as? MutableAsset {
            var status = ""
            if let comment = asset.comment?.trim where !comment.isEmpty {
                status += "4"
            }
            if asset.edited {
                status += "R"
            }
            if !status.isEmpty {
                statusLabel.attributedText = NSAttributedString(string: status, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor(),NSFontAttributeName:statusLabel.font])
            } else {
                statusLabel.attributedText = nil
            }
        }
    }
}
