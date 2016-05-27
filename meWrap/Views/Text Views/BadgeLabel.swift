//
//  BadgeLabel.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class BadgeLabel: Label {
    
    var value = 0 {
        willSet {
            text = String(newValue)
            hidden = newValue == 0
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        var size = super.intrinsicContentSize()
        size = CGSizeMake(size.width + 5, size.height + 5)
        layer.cornerRadius = size.height/2
        return size
    }
}