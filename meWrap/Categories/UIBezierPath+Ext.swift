//
//  UIBezierPath+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/19/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

func ^(lhs: CGFloat, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs, y: rhs)
}

extension UIBezierPath {
    
    func move(point: CGPoint) -> Self {
        moveToPoint(point)
        return self
    }
    
    func line(point: CGPoint) -> Self {
        addLineToPoint(point)
        return self
    }
    
    func quadCurve(point: CGPoint, controlPoint: CGPoint) -> Self {
        addQuadCurveToPoint(point, controlPoint: controlPoint)
        return self
    }
}
