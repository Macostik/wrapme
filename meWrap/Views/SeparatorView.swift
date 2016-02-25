//
//  SeparatorView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/22/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class SeparatorView: UIView {
    
    convenience init(color: UIColor, contentMode: UIViewContentMode = .Bottom) {
        self.init()
        backgroundColor = UIColor.clearColor()
        self.contentMode = contentMode
        self.color = color
    }
    
    @IBInspectable var color: UIColor?
    
    override func drawRect(rect: CGRect) {
        if let color = color {
            let path = UIBezierPath()
            switch contentMode {
            case .Top:
                path.move(0, 0).line(frame.width, 0)
            case .Left:
                path.move(0, 0).line(0, frame.height)
            case .Right:
                path.move(frame.width, 0).line(frame.width, frame.height)
            default:
                path.move(0, frame.height).line(frame.width, frame.height)
            }
            color.setStroke()
            path.lineWidth = 1.0 / max(2, UIScreen.mainScreen().scale)
            path.stroke()
        }
    }
}