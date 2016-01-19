//
//  UIBezierPath+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/19/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

extension UIBezierPath {
    
    func move(x: CGFloat, _ y: CGFloat) -> Self {
        moveToPoint(CGPoint(x: x, y: y))
        return self
    }
    
    func line(x: CGFloat, _ y: CGFloat) -> Self {
        addLineToPoint(CGPoint(x: x, y: y))
        return self
    }
    
    func quadCurve(x: CGFloat, _ y: CGFloat, controlX: CGFloat, controlY: CGFloat) -> Self {
        addQuadCurveToPoint(CGPoint(x: x, y: y), controlPoint: CGPoint(x: controlX, y: controlY))
        return self
    }
}
