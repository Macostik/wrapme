//
//  UIButton+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIButton {
    var active: Bool {
        set {
            setActive(newValue, animated: false)
        }
        get {
            return alpha > 0.5 && userInteractionEnabled
        }
    }
    
    func setActive(active: Bool, animated: Bool) {
        if (animated) {
            UIView.beginAnimations(nil, context: nil)
        }
        alpha = active ? 1.0 : 0.5
        userInteractionEnabled = active
        if (animated) {
            UIView.commitAnimations()
        }
    }
}