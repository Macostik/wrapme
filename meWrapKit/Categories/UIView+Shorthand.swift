//
//  UIView+Shorthand.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension UIView {
    
    var centerX: CGFloat {
        set {
            center.x = newValue
        }
        get {
            return center.x
        }
    }
    
    var centerY: CGFloat {
        set {
            center.y = newValue
        }
        get {
            return center.y
        }
    }
    
    var x: CGFloat {
        set {
            frame.origin.x = newValue
        }
        get {
            return frame.origin.x
        }
    }
    
    var y: CGFloat {
        set {
            frame.origin.y = newValue
        }
        get {
            return frame.origin.y
        }
    }
    
    var width: CGFloat {
        set {
            frame.size.width = newValue
        }
        get {
            return frame.size.width
        }
    }
    
    var height: CGFloat {
        set {
            frame.size.height = newValue
        }
        get {
            return frame.size.height
        }
    }
    
    var size: CGSize {
        set {
            frame.size = newValue
        }
        get {
            return frame.size
        }
    }
    
    var centerBoundary: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func setFullFlexible() {
        autoresizingMask = [.FlexibleBottomMargin, .FlexibleHeight, .FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleWidth]
    }

}