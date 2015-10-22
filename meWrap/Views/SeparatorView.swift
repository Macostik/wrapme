//
//  SeparatorView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/22/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class SeparatorView: UIView {
    @IBInspectable var color: UIColor?
    
    override func drawRect(rect: CGRect) {
        if let color = color {
            let path = UIBezierPath()
            switch contentMode {
            case .Top:
                path.moveToPoint(CGPoint(x: 0, y: 0))
                path.addLineToPoint(CGPoint(x: frame.width, y: 0))
            case .Left:
                path.moveToPoint(CGPoint(x: 0, y: 0))
                path.addLineToPoint(CGPoint(x: 0, y: frame.height))
            case .Right:
                path.moveToPoint(CGPoint(x: frame.width, y: 0))
                path.addLineToPoint(CGPoint(x: frame.width, y: frame.height))
            default:
                path.moveToPoint(CGPoint(x: 0, y: frame.height))
                path.addLineToPoint(CGPoint(x: frame.width, y: frame.height))
            }
            color.setStroke()
            path.lineWidth = 1.0 / max(2, UIScreen.mainScreen().scale)
            path.stroke()
        }
    }
}