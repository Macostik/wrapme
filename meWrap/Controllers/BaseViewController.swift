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

class BaseViewController: GAITrackedViewController {
    
    @IBInspectable var statusBarDefault = false
    
    @IBOutlet weak var navigationBar: UIView?
    
    var preferredViewFrame = UIWindow.mainWindow.bounds
    
    @IBOutlet lazy var keyboardAdjustmentLayoutViews: [UIView] = [self.view]
    
    var keyboardAdjustmentAnimated = true
    
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
        if !keyboardAdjustments.isEmpty {
            
            Keyboard.keyboard.handle(self, willShow: { [unowned self] (keyboard) in
                
                guard self.isViewLoaded() && !self.keyboardAdjustments.isEmpty else { return }
                self.adjust(keyboard)
                
                }, willHide: { [unowned self] (keyboard) in
                    
                    guard self.isViewLoaded() && !self.keyboardAdjustments.isEmpty else { return }
                    self.adjust(keyboard, willHide: true)
                    
                })
        }
        if !whenLoadedBlocks.isEmpty {
            whenLoadedBlocks.all({ $0() })
            whenLoadedBlocks.removeAll()
        }
    }
    
    private var whenLoadedBlocks = [Block]()
    
    func whenLoaded(block: Block) {
        if isViewLoaded() {
            block()
        } else {
            whenLoadedBlocks.append(block)
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
}