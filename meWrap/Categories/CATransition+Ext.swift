//
//  CATransition+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension CATransition {
    class func transition(type: String, subtype: String? = nil, duration: CFTimeInterval = 0.33) -> CATransition {
        let transition = CATransition()
        transition.type = type
        transition.subtype = subtype
        transition.duration = duration
        transition.fillMode = kCAFillModeBoth
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return transition
    }
}

extension UIView {
    
    func addAnimation(animation: CAAnimation) {
        addAnimation(animation, key: nil)
    }
    
    func addAnimation(animation: CAAnimation, key: String?) {
        layer.addAnimation(animation, forKey: key)
    }
    
}