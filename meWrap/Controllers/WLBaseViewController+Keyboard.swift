//
//  WLBaseViewController+Keyboard.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/19/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

extension WLBaseViewController: KeyboardNotifying {
    
    func constantForKeyboardAdjustmentBottomConstraint(constraint: NSLayoutConstraint, defaultConstant: CGFloat, keyboardHeight: CGFloat) -> CGFloat {
        let adjustment = keyboardAdjustmentForConstraint(constraint, defaultConstant:defaultConstant, keyboardHeight:keyboardHeight)
        return defaultConstant + adjustment
    }
    
    func constantForKeyboardAdjustmentTopConstraint(constraint: NSLayoutConstraint, defaultConstant: CGFloat, keyboardHeight: CGFloat) -> CGFloat {
        let adjustment = keyboardAdjustmentForConstraint(constraint, defaultConstant:defaultConstant, keyboardHeight:keyboardHeight)
        return defaultConstant - adjustment
    }
    
    func keyboardAdjustmentForConstraint(constraint: NSLayoutConstraint, defaultConstant: CGFloat, keyboardHeight: CGFloat) -> CGFloat {
        return keyboardHeight
    }
    
    private func updateKeyboardAdjustmentConstraints(keyboardHeight: CGFloat) -> Bool {
        var changed = false
        guard let constants = keyboardAdjustmentDefaultConstants else { return false }
        for constraint in keyboardAdjustmentTopConstraints ?? [] {
            let constraint = constraint as! NSLayoutConstraint
            var constant: CGFloat = constants.objectForKey(constraint) as? CGFloat ?? 0
            if keyboardHeight > 0 {
                constant = constantForKeyboardAdjustmentTopConstraint(constraint, defaultConstant:constant, keyboardHeight:keyboardHeight)
            }
            if constraint.constant != constant {
                constraint.constant = constant
                changed = true
            }
        }
        for constraint in keyboardAdjustmentBottomConstraints ?? [] {
            let constraint = constraint as! NSLayoutConstraint
            var constant: CGFloat = constants.objectForKey(constraint) as? CGFloat ?? 0
            if keyboardHeight > 0 {
                constant = constantForKeyboardAdjustmentBottomConstraint(constraint, defaultConstant:constant, keyboardHeight:keyboardHeight)
            }
            if constraint.constant != constant {
                constraint.constant = constant
                changed = true
            }
        }
        return changed
    }
    
    private func layoutKeyboardAdjustmentViews() {
        for layoutView in keyboardAdjustmentLayoutViews ?? [] {
            layoutView.layoutIfNeeded()
        }
    }
    
    private func layoutKeyboardAdjustmentView(keyboard: Keyboard) {
        if keyboardAdjustmentAnimated && viewAppeared {
            keyboard.performAnimation({ layoutKeyboardAdjustmentViews() })
        } else {
            layoutKeyboardAdjustmentViews()
        }
    }
    
    func keyboardWillShow(keyboard: Keyboard) {
        guard isViewLoaded() && (keyboardAdjustmentTopConstraints?.isEmpty == false || keyboardAdjustmentBottomConstraints?.isEmpty == false) else { return }
        if updateKeyboardAdjustmentConstraints(keyboard.height) {
            layoutKeyboardAdjustmentView(keyboard)
        }
    }
    
    func keyboardDidShow(keyboard: Keyboard) { }
    
    func keyboardWillHide(keyboard: Keyboard) {
        guard isViewLoaded() && (keyboardAdjustmentTopConstraints?.isEmpty == false || keyboardAdjustmentBottomConstraints?.isEmpty == false) else { return }
        updateKeyboardAdjustmentConstraints(0)
        keyboardAdjustmentDefaultConstants = nil
        layoutKeyboardAdjustmentView(keyboard)
    }
    
    func keyboardDidHide(keyboard: Keyboard) { }
}