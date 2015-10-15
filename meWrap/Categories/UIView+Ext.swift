//
//  UIView+Additions.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIView {
    
    // MARK: - Regular Animation
    
    class func performAnimated(animated: Bool, animation:((Void) -> (Void))?) {
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
        }
        animation?()
        if animated {
            UIView.commitAnimations()
        }
    }
    
    func setAlpha(alpha: CGFloat, animated: Bool) {
        UIView.performAnimated(animated) {[unowned self] () -> (Void) in
            self.alpha = alpha
        }
    }
    
    func setTransform(transform: CGAffineTransform, animated: Bool) {
        UIView.performAnimated(animated) {[unowned self] () -> (Void) in
            self.transform = transform
        }
    }
    
    func setBackgroundColor(backgroundColor: UIColor, animated: Bool) {
        UIView.performAnimated(animated) {[unowned self] () -> (Void) in
            self.backgroundColor = backgroundColor
        }
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
    
    // MARK: - Constraints
    
    func makeResizibleSubview(view: UIView) {
        addConstraint(view.constraintToItem(self, equal:.CenterX))
        addConstraint(view.constraintToItem(self, equal:.CenterY))
        addConstraint(view.constraintToItem(self, equal:.Width))
        addConstraint(view.constraintToItem(self, equal:.Height))
    }
    
    func constraintToItem(item: AnyObject, equal attribute: NSLayoutAttribute) -> NSLayoutConstraint {
        return constraintForAttrbute(attribute, toItem: item, equalToAttribute: attribute)
    }
    
    func constraintForAttrbute(attribute1: NSLayoutAttribute, toItem item: AnyObject, equalToAttribute attribute2: NSLayoutAttribute) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self, attribute: attribute1, relatedBy: .Equal, toItem: item, attribute: attribute2, multiplier: 1, constant: 0)
    }
    
    // MARK: - QuartzCore
    
    @IBInspectable var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.CGColor
        }
        get {
            guard let color = layer.borderColor else {
                return nil
            }
            return UIColor(CGColor: color);
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var circled: Bool {
        set {
            cornerRadius = circled ? bounds.height/2.0 : 0
        }
        get {
            return cornerRadius == bounds.height/2.0
        }
    }
}