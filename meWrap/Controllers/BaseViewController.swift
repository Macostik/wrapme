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

func performWhenLoaded<T: BaseViewController>(controller: T, block: T -> ()) {
    controller.whenLoaded { [weak controller] in
        if let controller = controller {
            block(controller)
        }
    }
}

class BaseViewController: GAITrackedViewController, KeyboardNotifying {
    
    @IBInspectable var statusBarDefault = false
    
    @IBOutlet weak var navigationBar: UIView?
    
    var preferredViewFrame = UIWindow.mainWindow.bounds
    
    @IBOutlet lazy var keyboardAdjustmentLayoutViews: [UIView] = [self.view]
    
    var keyboardAdjustmentAnimated = true
    
    @IBOutlet weak var keyboardBottomGuideView: UIView?
    
    var viewAppeared = false
    
    private lazy var keyboardAdjustments: [KeyboardAdjustment] = [] 
    
    @IBOutlet var keyboardAdjustmentBottomConstraints: [NSLayoutConstraint] = []
    @IBOutlet var keyboardAdjustmentTopConstraints: [NSLayoutConstraint] = []
    
    deinit {
        Logger.debugLog("\(NSStringFromClass(self.dynamicType)) deinit", color: .Blue)
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
            view.forceLayout()
        }
        var adjustments: [KeyboardAdjustment] = self.keyboardAdjustmentBottomConstraints.map({ KeyboardAdjustment(constraint: $0) })
        adjustments += self.keyboardAdjustmentTopConstraints.map({ KeyboardAdjustment(constraint: $0, isBottom: false) })
        keyboardAdjustments = adjustments
        screenName = NSStringFromClass(self.dynamicType)
        if keyboardBottomGuideView != nil || !keyboardAdjustments.isEmpty {
            Keyboard.keyboard.addReceiver(self)
        }
        if !whenLoadedBlocks.isEmpty {
            whenLoadedBlocks.all({ $0.block() })
            whenLoadedBlocks.removeAll()
        }
    }
    
    private struct WhenLoadedBlock {
        let block: () -> ()
    }
    
    private var whenLoadedBlocks = [WhenLoadedBlock]()
    
    func whenLoaded(block: () -> ()) {
        if isViewLoaded() {
            block()
        } else {
            whenLoadedBlocks.append(WhenLoadedBlock(block: block))
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
        if let keyboardBottomGuideView = keyboardBottomGuideView {
            keyboard.performAnimation({ () in
                keyboardBottomGuideView.snp_updateConstraints(closure: { (make) in
                    make.bottom.equalTo(view).inset(keyboard.height)
                })
                view.layoutIfNeeded()
            })
        } else {
            guard isViewLoaded() && !keyboardAdjustments.isEmpty else { return }
            adjust(keyboard)
        }
    }
    
    func keyboardDidShow(keyboard: Keyboard) {}
    
    func keyboardWillHide(keyboard: Keyboard) {
        if let keyboardBottomGuideView = keyboardBottomGuideView {
            keyboard.performAnimation({ () in
                keyboardBottomGuideView.snp_updateConstraints(closure: { (make) in
                    make.bottom.equalTo(view)
                })
                view.layoutIfNeeded()
            })
        } else {
            guard isViewLoaded() && !keyboardAdjustments.isEmpty else { return }
            adjust(keyboard, willHide: true)
        }
    }
    
    func keyboardDidHide(keyboard: Keyboard) {}
}