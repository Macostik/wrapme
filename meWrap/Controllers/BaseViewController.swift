//
//  BaseViewController+Keyboard.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/19/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class BaseViewController: GAITrackedViewController {
    
    @IBInspectable var statusBarDefault = false
    
    @IBOutlet weak var navigationBar: UIView?
    
    var preferredViewFrame = UIWindow.mainWindow.bounds
    
    @IBOutlet lazy var keyboardAdjustmentLayoutViews: [UIView] = [self.view]
    
    var keyboardAdjustmentAnimated = true
    
    var viewAppeared = false
    
    @IBOutlet var keyboardAdjustmentBottomConstraints: [NSLayoutConstraint] = []
    
    @IBOutlet var keyboardAdjustmentTopConstraints: [NSLayoutConstraint] = []
    
    private lazy var keyboardAdjustmentDefaultConstants: [NSLayoutConstraint : CGFloat] = {
        var constants = [NSLayoutConstraint : CGFloat]()
        for constraint in self.keyboardAdjustmentTopConstraints {
            constants[constraint] = constraint.constant
        }
        for constraint in self.keyboardAdjustmentBottomConstraints {
            constants[constraint] = constraint.constant
        }
        return constants
    }()
    
    deinit {
        #if DEBUG
            Logger.debugLog("\(NSStringFromClass(self.dynamicType)) deinit", color: .Blue)
        #endif
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return !statusBarDefault ? .LightContent : .Default
    }
    
    override func loadView() {
        super.loadView()
        if shouldUsePreferredViewFrame() {
            view.frame = preferredViewFrame
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if shouldUsePreferredViewFrame() {
            view.layoutIfNeeded()
        }
        screenName = NSStringFromClass(self.dynamicType)
        Keyboard.keyboard.addReceiver(self)
    }
    
    func shouldUsePreferredViewFrame() -> Bool {
        return true
    }
    
    static var lastAppearedScreenName: String?
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewAppeared = true
        BaseViewController.lastAppearedScreenName = screenName
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        viewAppeared = false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
}

extension BaseViewController: KeyboardNotifying {
    
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
        let constants = keyboardAdjustmentDefaultConstants
        for constraint in keyboardAdjustmentTopConstraints {
            let constraint = constraint
            var constant: CGFloat = constants[constraint] ?? 0
            if keyboardHeight > 0 {
                constant = constantForKeyboardAdjustmentTopConstraint(constraint, defaultConstant:constant, keyboardHeight:keyboardHeight)
            }
            if constraint.constant != constant {
                constraint.constant = constant
                changed = true
            }
        }
        for constraint in keyboardAdjustmentBottomConstraints {
            let constraint = constraint
            var constant: CGFloat = constants[constraint] ?? 0
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
        guard isViewLoaded() && (keyboardAdjustmentTopConstraints.isEmpty == false || keyboardAdjustmentBottomConstraints.isEmpty == false) else { return }
        if updateKeyboardAdjustmentConstraints(keyboard.height) {
            layoutKeyboardAdjustmentView(keyboard)
        }
    }
    
    func keyboardDidShow(keyboard: Keyboard) { }
    
    func keyboardWillHide(keyboard: Keyboard) {
        guard isViewLoaded() && (keyboardAdjustmentTopConstraints.isEmpty == false || keyboardAdjustmentBottomConstraints.isEmpty == false) else { return }
        updateKeyboardAdjustmentConstraints(0)
        layoutKeyboardAdjustmentView(keyboard)
    }
    
    func keyboardDidHide(keyboard: Keyboard) { }
}