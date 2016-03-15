//
//  CATransition+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

func specifyObject<T>(object: T, @noescape _ specify: T -> Void) -> T {
    specify(object)
    return object
}

func specifyAnimation<T: CAAnimation>(animation: T, @noescape _ specify: T -> Void) -> T {
    return specifyObject(animation, specify)
}

extension CATransition {
    
    class func transition(type: String, subtype: String? = nil, duration: CFTimeInterval = 0.33) -> CATransition {
        return specifyAnimation(CATransition(), {
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
    
    func addAnimation<T: CAAnimation>(animation: T, @noescape specify: T -> Void) {
        layer.addAnimation(animation, specify: specify)
    }
}

extension CALayer {
    
    func addAnimation<T: CAAnimation>(animation: T, @noescape specify: T -> Void) {
        addAnimation(specifyAnimation(animation, specify), forKey: nil)
    }
}