//
//  GradientView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/22/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class GradientView: UIView {

    @IBInspectable var startColor: UIColor? {
        didSet {
            updateColors()
        }
    }
    
    @IBInspectable var endColor: UIColor? {
        didSet {
            updateColors()
        }
    }
    
    @IBInspectable var startLocation: CGFloat = 0 {
        didSet {
            updateLocations()
        }
    }
    
    @IBInspectable var endLocation: CGFloat = 1 {
        didSet {
            updateLocations()
        }
    }
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        awake()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        awake()
    }
    
    private func awake() {
        updateColors()
        updateLocations()
        let layer = self.layer as! CAGradientLayer
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale
    }
    
    private func updateColors() {
        guard let startColor = startColor else {
            return
        }
        
        let layer = self.layer as! CAGradientLayer
        
        var colors = [CGColorRef]()
        
        colors.append(startColor.CGColor)
        
        if let endColor = endColor {
            colors.append(endColor.CGColor)
        } else {
            let endColor = startColor.colorWithAlphaComponent(0)
            colors.append(endColor.CGColor)
            self.endColor = endColor
        }
        layer.colors = colors
    }
    
    private func updateLocations() {
        let layer = self.layer as! CAGradientLayer
        layer.locations = [startLocation, endLocation]
    }
    
    override var contentMode: UIViewContentMode {
        didSet {
            let layer = self.layer as! CAGradientLayer
            switch contentMode {
            case .Top:
                layer.startPoint = CGPoint(x: 0.5, y: 0);
                layer.endPoint = CGPoint(x: 0.5, y: 1);
            case .Left:
                layer.startPoint = CGPoint(x: 0, y: 0.5);
                layer.endPoint = CGPoint(x: 1, y: 0.5);
            case .Right:
                layer.startPoint = CGPoint(x: 1, y: 0.5);
                layer.endPoint = CGPoint(x: 0, y: 0.5);
            default:
                layer.startPoint = CGPoint(x: 0.5, y: 1);
                layer.endPoint = CGPoint(x: 0.5, y: 0);
            }
        }
    }
}
