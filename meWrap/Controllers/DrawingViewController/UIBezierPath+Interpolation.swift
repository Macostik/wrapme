//
//  UIBezierPath+Interpolation.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/24/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

extension CGPoint {
    
    func add(point: CGPoint) -> CGPoint {
        return CGPoint(x: x + point.x, y: y + point.y)
    }
    
    func subtract(point: CGPoint) -> CGPoint {
        return CGPoint(x: x - point.x, y: y - point.y)
    }
    
    func multiply(value: CGFloat) -> CGPoint {
        return CGPoint(x: x * value, y: y * value)
    }
    
    func dot(point: CGPoint) -> CGFloat {
        return x * point.x + y * point.y
    }
    
    func length() -> CGFloat {
        return sqrt(dot(self))
    }
}

extension UIBezierPath {
    class func hermiteIntepolation(points: [CGPoint], closed: Bool) -> UIBezierPath? {
        if points.count < 2 {
            return nil
        }
        
        let nCurves = closed ? points.count : points.count - 1
        
        let path = UIBezierPath()
        for ii in 0..<nCurves {
            var curPt  = points[ii]
            
            if ii==0 {
                path.moveToPoint(curPt)
            }
            
            var nextii = (ii + 1) % points.count
            var previi = (ii - 1 < 0 ? points.count - 1 : ii - 1)
            
            var prevPt = points[previi]
            var nextPt = points[nextii]
            
            let endPt = nextPt
            
            var mx: CGFloat = 0, my: CGFloat = 0
            if closed || ii > 0 {
                mx = (nextPt.x - curPt.x) * 0.5 + (curPt.x - prevPt.x) * 0.5
                my = (nextPt.y - curPt.y) * 0.5 + (curPt.y - prevPt.y) * 0.5
            } else {
                mx = (nextPt.x - curPt.x) * 0.5
                my = (nextPt.y - curPt.y) * 0.5
            }
            
            let ctrlPt1 = CGPoint(x: curPt.x + mx / 3.0, y: curPt.y + my / 3.0)
            
            curPt = points[nextii]
            
            nextii = (nextii + 1) % points.count
            previi = ii
            
            prevPt = points[previi]
            nextPt = points[nextii]
            
            if closed || ii < nCurves - 1 {
                mx = (nextPt.x - curPt.x) * 0.5 + (curPt.x - prevPt.x) * 0.5
                my = (nextPt.y - curPt.y) * 0.5 + (curPt.y - prevPt.y) * 0.5
            } else {
                mx = (curPt.x - prevPt.x) * 0.5
                my = (curPt.y - prevPt.y) * 0.5
            }
            
            let ctrlPt2 = CGPoint(x: curPt.x - mx / 3.0, y: curPt.y - my / 3.0)
            
            path.addCurveToPoint(endPt, controlPoint1: ctrlPt1, controlPoint2: ctrlPt2)
        }
        
        if closed {
            path.closePath()
        }
        
        return path
    }
}
