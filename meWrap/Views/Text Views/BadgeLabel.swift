//
//  BadgeLabel.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class BadgeLabel: Label {
    
    @IBInspectable lazy var intrinsicContentSizeInsets: CGSize = self.intrinsicContentSize()
    
    var value = 0 {
        willSet {
            text = String(newValue)
        }
    }
    
    override var text: String? {
        willSet {
            if let string = newValue where !string.isEmpty {
                super.text = text
                hidden = string == "0"
            }
        }
    }
    
    override var attributedText: NSAttributedString? {
        didSet {
            super.attributedText = attributedText
            if let string = attributedText?.string where !string.isEmpty {
                 hidden = string == "0"
            }
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        let insets = intrinsicContentSizeInsets
        var size = super.intrinsicContentSize()
        size = CGSizeMake(size.width + insets.width, size.height + insets.height);
        layer.cornerRadius = size.height/2
        return size
    }
}