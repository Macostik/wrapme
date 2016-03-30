//
//  BaseViewController+Keyboard.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/19/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

struct KeyboardAdjustment {
    let isBottom: Bool
    let defaultConstant: CGFloat
    let constraint: NSLayoutConstraint
    init(constraint: NSLayoutConstraint, isBottom: Bool = true) {
        self.isBottom = isBottom
        self.constraint = constraint
        self.defaultConstant = constraint.constant
    }
}

class BaseViewController: GAITrackedViewController, KeyboardNotifying {
    
    @IBInspectable var statusBarDefault = false
    
    @IBOutlet weak var navigationBar: UIView?
    
    var preferredViewFrame = UIWindow.mainWindow.bounds
    
    @IBOutlet lazy var keyboardAdjustmentLayoutViews: [UIView] = [self.view]
    
    var keyboardAdjustmentAnimated = true
    
    var viewAppeared = false
    
    private lazy var keyboardAdjustments: [KeyboardAdjustment] = {
        var adjustments = self.keyboardAdjustmentBottomConstraints.map({ KeyboardAdjustment(constraint: $0) })
        adjustments += self.keyboardAdjustmentTopConstraints.map({ KeyboardAdjustment(constraint: $0, isBottom: false) })
        return adjustments
    }()
    
    @IBOutlet var keyboardAdjustmentBottomConstraints: [NSLayoutConstraint] = []
    @IBOutlet var keyboardAdjustmentTopConstraints: [NSLayoutConstraint] = []
    
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
        if !keyboardAdjustments.isEmpty {
            Keyboard.keyboard.addReceiver(self)
        }
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
    
    func keyboardAdjustmentConstant(adjustment: KeyboardAdjustment, keyboard: Keyboard) -> CGFloat {
        if adjustment.isBottom {
            return adjustment.defaultConstant + keyboard.height
        } else {
            return adjustment.defaultConstant - keyboard.height
        }
    }
    
    private func adjust(keyboard: Keyboard, willHide: Bool = false) {
        keyboardAdjustments.all({
            $0.constraint.constant = willHide ? $0.defaultConstant : keyboardAdjustmentConstant($0, keyboard:keyboard)
        })
        if keyboardAdjustmentAnimated && viewAppeared {
            keyboard.performAnimation({ keyboardAdjustmentLayoutViews.all { $0.layoutIfNeeded() } })
        } else {
            keyboardAdjustmentLayoutViews.all { $0.layoutIfNeeded() }
        }
    }
    
    func keyboardWillShow(keyboard: Keyboard) {
        guard isViewLoaded() && !keyboardAdjustments.isEmpty else { return }
        adjust(keyboard)
    }
    
    func keyboardDidShow(keyboard: Keyboard) {}
    
    func keyboardWillHide(keyboard: Keyboard) {
        guard isViewLoaded() && !keyboardAdjustments.isEmpty else { return }
        adjust(keyboard, willHide: true)
    }
    
    func keyboardDidHide(keyboard: Keyboard) {}
}