//
//  ColorPicker.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class ColorPicker: UIView {
    
    var pickedColor: (UIColor -> Void)?
    
    private let colorsView = UIView()
    
    private let targetLabel = UIView()
    
    private var colors: [UIColor] = []
    
    func setup() {
        
        colorsView.userInteractionEnabled = false
        colorsView.clipsToBounds = true
        colorsView.cornerRadius = 3
        colorsView.frame = bounds.insetBy(dx: 20, dy: 10)
        addSubview(colorsView)
        
        var colors = [UIColor]()
        let hueWidth = colorsView.width - 20
        for i in 0...Int(hueWidth) {
            let hue = CGFloat(i)/hueWidth
            colors.append(UIColor(hue:hue, saturation:1.0, brightness:1.0, alpha:1.0))
        }
        for _ in 0...10 {
            colors.append(UIColor.blackColor())
        }
        for _ in 0...10 {
            colors.append(UIColor.whiteColor())
        }
        setColors(colors)
        
        targetLabel.userInteractionEnabled = false
        targetLabel.cornerRadius = 3
        targetLabel.setBorder(color: UIColor.whiteColor())
        targetLabel.layer.shadowColor = UIColor.blackColor().CGColor
        targetLabel.layer.shadowOpacity = 0.5
        targetLabel.layer.shadowOffset = CGSize(width: 0, height: 0)
        targetLabel.frame = colorsView.frame.origin ^ (10 ^ colorsView.height)
        addSubview(targetLabel)
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.panning(_:))))
    }
    
    func panning(sender: UIPanGestureRecognizer) {
        if sender.state == .Changed {
            let x = targetLabel.x + sender.translationInView(self).x
            targetLabel.x = smoothstep(colorsView.frame.minX, colorsView.frame.maxX - targetLabel.width, x)
            sender.setTranslation(CGPoint.zero, inView: self)
        }
        let index = Int(targetLabel.center.x - colorsView.x)
        if let color = colors[safe: index] {
            pickedColor?(color)
        }
    }
    
    private func setColors(colors: [UIColor]) {
        var x: CGFloat = 0
        let size: CGSize = colorsView.width / CGFloat(colors.count) ^ colorsView.height
        for color in colors {
            let view = UIView(frame: x ^ 0 ^ size)
            view.backgroundColor = color
            colorsView.addSubview(view)
            x += size.width
        }
        self.colors = colors
    }
}