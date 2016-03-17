//
//  CATransition+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

func specify<T>(object: T, @noescape _ specify: T -> Void) -> T {
    specify(object)
    return object
}

extension CATransition {
    
    class func transition(type: String, subtype: String? = nil, duration: CFTimeInterval = 0.33) -> CATransition {
        return specify(CATransition(), {
            $0.type = type
            $0.subtype = subtype
            $0.duration = duration
            $0.fillMode = kCAFillModeBoth
            $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        })
    }
}

extension UIView {
    
    func addAnimation(animation: CAAnimation, key: String? = nil) {
        layer.addAnimation(animation, forKey: key)
    }
    
    func addAnimation<T: CAAnimation>(animation: T, @noescape _ specify: T -> Void) {
        layer.addAnimation(animation, specify)
    }
}

extension CALayer {
    
    func addAnimation<T: CAAnimation>(animation: T, @noescape _ _specify: T -> Void) {
        addAnimation(specify(animation, _specify), forKey: nil)
    }
}