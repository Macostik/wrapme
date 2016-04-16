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
    
    func defineShapePath(path: UIBezierPath, contentMode: UIViewContentMode) { }
}

class TriangleView: ShapeView {

    override func defineShapePath(path: UIBezierPath, contentMode: UIViewContentMode) {
        let r = bounds
        switch contentMode {
        case .Top:
            path.move(r.minX ^ r.maxY).line(r.maxX ^ r.maxY).line(r.midX ^ r.minY).line(r.minX ^ r.maxY)
            break
        case .Left:
            path.move(r.minX ^ r.minY).line(r.minX ^ r.maxY).line(r.maxX ^ r.midY).line(r.minX ^ r.minY)
            break
        case .Right:
            path.move(r.maxX ^ r.minY).line(r.minX ^ r.midY).line(r.maxX ^ r.maxY).line(r.maxX ^ r.minY)
            break
        case .Bottom:
            path.move(r.minX ^ r.minY).line(r.maxX ^ r.minY).line(r.midX ^ r.maxY).line(r.minX ^ r.minY)
            break
        default:
            path.move(r.minX ^ r.maxY).line(r.maxX ^ r.maxY).line(r.midX ^ r.minY).line(r.minX ^ r.maxY)
            break
        }
    }
}
