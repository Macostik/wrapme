//
//  BadgeLabel.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class BadgeLabel: Label {
    
    @IBInspectable var intrinsicContentSizeInsets: CGSize = CGSize.zero
    
    var value = 0 {
        willSet {
            text = String(newValue)
        }
    }
    
    override var text: String? {
        willSet {
            if let string = newValue {
                hidden = string.isEmpty || string == "0"
            } else {
                hidden = true
            }
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        let insets = intrinsicContentSizeInsets
        var size = super.intrinsicContentSize()
        size = CGSizeMake(size.width + insets.width, size.height + insets.height)
        layer.cornerRadius = size.height/2
        return size
    }
}