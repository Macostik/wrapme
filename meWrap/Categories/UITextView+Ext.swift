//
//  UITextView+Aditions.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UITextView {
    func determineHyperLink(string: String?) {
        if let string = string {
            if let font = font {
                let attributes = [NSFontAttributeName:font,NSForegroundColorAttributeName:textColor ?? UIColor.blackColor()]
                attributedText = NSAttributedString(string: string, attributes: attributes)
            }
        } else {
            text = nil
        }
    }
}

