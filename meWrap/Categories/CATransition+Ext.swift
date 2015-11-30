//
//  CATransition+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension CATransition {
    
    class func transition(type: String) -> CATransition {
        return transition(type, subtype: nil, duration: 0.33)
    }
    
    class func transition(type: String, subtype: String?) -> CATransition {
        return transition(type, subtype: subtype, duration: 0.33)
    }
    
    class func transition(type: String, duration: CFTimeInterval) -> CATransition {
        return transition(type, subtype: nil, duration: duration)
    }
    
    class func transition(type: String, subtype: String?, duration: CFTimeInterval) -> CATransition {
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