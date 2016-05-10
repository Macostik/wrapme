//
//  LayoutPrioritizer.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/21/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class LayoutPrioritizer: NSObject {
    
    @IBOutlet var defaultConstraints: Array<NSLayoutConstraint> = []
    
    @IBOutlet var alternativeConstraints: Array<NSLayoutConstraint> = []
    
    @IBOutlet var parentViews: Array<UIView> = []
    
    @IBInspectable var animated: Bool = false
    
    @IBInspectable var asynchronous: Bool = false
    
    func setDefaultState(state: Bool, animated: Bool) {
    
        if defaultState != state {
            
            animate(animated, duration: 0.25, curve: .EaseInOut, animations: {
                for constraint in defaultConstraints {
                    constraint.priority = state ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow
                }
                
                for constraint in alternativeConstraints {
                    constraint.priority = state ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh
                }
                
                if parentViews.count > 0 {
                    for view in parentViews {
                        (animated || !asynchronous) ? view.layoutIfNeeded() : view.setNeedsLayout()
                    }
                } else {
                    if let view = (defaultConstraints.first?.firstItem as? UIView)?.superview {
                        (animated || !asynchronous) ? view.layoutIfNeeded() : view.setNeedsLayout()
                    }
                }
            })
        }
    }
    
    var defaultState: Bool {
        set {
            setDefaultState(newValue, animated: animated)
        }
        get {
            return defaultConstraints.first?.priority > alternativeConstraints.first?.priority
        }
    }
    
    @IBAction func enableDefaultState(sender: UIControl) {
        defaultState = false
    }
    
    @IBAction func enableAlternativeState(sender: UIControl) {
        defaultState = true
    }
    
    @IBAction func toggleState(sender: UIControl) {
        defaultState = !defaultState
    }
}