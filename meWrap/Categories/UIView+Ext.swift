//
//  UIView+Additions.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

func animate(animated: Bool = true, duration: NSTimeInterval = 0.3, curve: UIViewAnimationCurve = .EaseInOut, @noescape animations: () -> ()) {
    if animated {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationBeginsFromCurrentState(true)
    }
    animations()
    if animated {
        UIView.commitAnimations()
    }
}

extension UIView {
    
    var x: CGFloat {
        set { frame.origin.x = newValue }
        get { return frame.origin.x }
    }
    
    var y: CGFloat {
        set { frame.origin.y = newValue }
        get { return frame.origin.y }
    }
    
    var width: CGFloat {
        set { frame.size.width = newValue }
        get { return frame.size.width }
    }
    
    var height: CGFloat {
        set { frame.size.height = newValue }
        get { return frame.size.height }
    }
    
    var size: CGSize {
        set { frame.size = newValue }
        get { return frame.size }
    }
    
    var centerBoundary: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func add<T: UIView>(subview: T) -> T {
        addSubview(subview)
        return subview
    }
    
    func add<T: UIView>(subview: T, @noescape _ layout: (make: ConstraintMaker) -> Void) -> T {
        addSubview(subview)
        subview.snp_makeConstraints(closure: layout)
        return subview
    }
    
    func forceLayout() {
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // MARK: - Regular Animation
    
    class func performAnimated( animated: Bool, @noescape animation: Void -> Void) {
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
        }
        animation()
        if animated {
            UIView.commitAnimations()
        }
    }
    
    func setAlpha(alpha: CGFloat, animated: Bool) {
        UIView.performAnimated(animated) { self.alpha = alpha }
    }
    
    func setTransform(transform: CGAffineTransform, animated: Bool) {
        UIView.performAnimated(animated) { self.transform = transform }
    }
    
    func setBackgroundColor(backgroundColor: UIColor, animated: Bool) {
        UIView.performAnimated(animated) { self.backgroundColor = backgroundColor }
    }
    
    func findFirstResponder() -> UIView? {
        if self.isFirstResponder() {
            return self
        }
        for subView in self.subviews {
            if let firstResponder = subView.findFirstResponder() {
                return firstResponder
            }
        }
        return nil
    }
    
    // MARK: - QuartzCore
    
    @IBInspectable var borderColor: UIColor? {
        set { layer.borderColor = newValue?.CGColor }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(CGColor: color);
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        set { layer.borderWidth = newValue }
        get { return layer.borderWidth }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set { layer.cornerRadius = newValue }
        get { return layer.cornerRadius }
    }
    
    @IBInspectable var circled: Bool {
        set {
            cornerRadius = newValue ? bounds.height/2.0 : 0
            Dispatch.mainQueue.async {
                self.cornerRadius = newValue ? self.bounds.height/2.0 : 0
            }
        }
        get {
            return cornerRadius == bounds.height/2.0
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        set { layer.shadowColor = newValue?.CGColor }
        get {
            guard let color = layer.shadowColor else { return nil }
            return UIColor(CGColor: color)
        }
    }
    
    @IBInspectable var shadowOffset: CGSize {
        set { layer.shadowOffset = newValue }
        get { return layer.shadowOffset }
    }
    
    @IBInspectable var shadowOpacity: Float {
        set { layer.shadowOpacity = newValue }
        get { return layer.opacity }
    }
}

extension UIButton {
    
    var active: Bool {
        set { setActive(newValue, animated: false) }
        get { return alpha > 0.5 && userInteractionEnabled }
    }
    
    func setActive(active: Bool, animated: Bool) {
        setAlpha(active ? 1.0 : 0.5, animated: animated)
        userInteractionEnabled = active
    }
    
    func addTarget(target: AnyObject?, touchUpInside: Selector) {
        addTarget(target, action: touchUpInside, forControlEvents: .TouchUpInside)
    }
}