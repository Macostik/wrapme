//
//  ShapeView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class ShapeView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
    
        let path = UIBezierPath()
        
        defineShapePath(path, contentMode:contentMode)
        
        let shape = CAShapeLayer()
        shape.path = path.CGPath
        shape.frame = bounds
        layer.mask = shape
    }
    
    func defineShapePath(path: UIBezierPath, contentMode: UIViewContentMode) {
    
    }
}

class TriangleView: ShapeView {

    override func defineShapePath(path: UIBezierPath, contentMode: UIViewContentMode) {
        let rect = bounds
        switch contentMode {
        case .Top:
            path.moveToPoint(CGPointMake(rect.minX, rect.maxY))
            path.addLineToPoint(CGPointMake(rect.maxX, rect.maxY))
            path.addLineToPoint(CGPointMake(rect.midX, rect.minY))
            path.addLineToPoint(CGPointMake(rect.minX, rect.maxY))
            break
        case .Left:
            path.moveToPoint(CGPointMake(rect.minX, rect.minY))
            path.addLineToPoint(CGPointMake(rect.minX, rect.maxY))
            path.addLineToPoint(CGPointMake(rect.maxX, rect.midY))
            path.addLineToPoint(CGPointMake(rect.minX, rect.minY))
            break
        case .Right:
            path.moveToPoint(CGPointMake(rect.maxX, rect.minY))
            path.addLineToPoint(CGPointMake(rect.minX, rect.midY))
            path.addLineToPoint(CGPointMake(rect.maxX, rect.maxY))
            path.addLineToPoint(CGPointMake(rect.maxX, rect.minY))
            break
        case .Bottom:
            path.moveToPoint(CGPointMake(rect.minX, rect.minY))
            path.addLineToPoint(CGPointMake(rect.maxX, rect.minY))
            path.addLineToPoint(CGPointMake(rect.midX, rect.maxY))
            path.addLineToPoint(CGPointMake(rect.minX, rect.minY))
            break
        default:
            break
        }
    }
}

class SwipeActionView: ShapeView {

    override func defineShapePath(path: UIBezierPath, contentMode: UIViewContentMode) {
        let rect = bounds
        let height = rect.height
        let width = rect.width
        if contentMode == .Left {
            path.moveToPoint(CGPointMake(0, 0))
            path.addLineToPoint(CGPointMake(0, height))
            path.addLineToPoint(CGPointMake(width - height/2.0, height))
            path.addLineToPoint(CGPointMake(width, height/2.0))
            path.addLineToPoint(CGPointMake(width - height/2.0, 0))
            path.moveToPoint(CGPointMake(0, 0))
        } else if (contentMode == .Right) {
            path.moveToPoint(CGPointMake(width, 0))
            path.addLineToPoint(CGPointMake(height/2.0, 0))
            path.addLineToPoint(CGPointMake(0, height/2.0))
            path.addLineToPoint(CGPointMake(height/2.0, height))
            path.addLineToPoint(CGPointMake(width, height))
            path.moveToPoint(CGPointMake(width, 0))
        }
    }

}
