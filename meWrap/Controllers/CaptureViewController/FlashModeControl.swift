//
//  FlashModeControl.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AVFoundation

private extension AVCaptureFlashMode {
    func stringValue() -> String {
        switch self {
        case .On: return "d"
        case .Off: return "c"
        case .Auto: return "b"
        }
    }
}

class FlashModeButton: UIButton {
    var mode: AVCaptureFlashMode = .Off {
        didSet {
            setTitle(mode.stringValue(), forState: .Normal)
        }
    }
    
    class func button(mode: AVCaptureFlashMode) -> FlashModeButton {
        let button = FlashModeButton(type: .Custom)
        button.titleLabel?.font = UIFont(name: "icons", size:24)
        button.mode = mode
        return button
    }
}

class FlashModeControl: UIControl {

    private var onButton = FlashModeButton.button(.On)
    private var offButton = FlashModeButton.button(.Off)
    private var autoButton = FlashModeButton.button(.Auto)
    private var currentModeButton = FlashModeButton.button(.Off)
    @IBOutlet weak var widthConstraint: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initializeButton(currentModeButton, action: #selector(FlashModeControl.changeMode(_:)))
        initializeButton(onButton, action: #selector(FlashModeControl.selectMode(_:)))
        initializeButton(offButton, action: #selector(FlashModeControl.selectMode(_:)))
        initializeButton(autoButton, action: #selector(FlashModeControl.selectMode(_:)))
        selecting = false
    }
    
    private func initializeButton(button: UIButton, action: Selector) {
        button.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: height, height: height)
        addSubview(button)
    }
    
    var mode: AVCaptureFlashMode = .Off {
        didSet {
            currentModeButton.mode = mode
        }
    }
    
    private var selecting = false {
        didSet {
            let selecting = self.selecting
            currentModeButton.alpha = selecting ? 0 : 1
            onButton.alpha = selecting ? 1 : 0
            offButton.alpha = selecting ? 1 : 0
            autoButton.alpha = selecting ? 1 : 0
            offButton.x = selecting ? height : 0
            autoButton.x = selecting ? (2 * height) : 0
            if let constraint = widthConstraint {
                constraint.constant = selecting ? (height * 3) : height
                layoutIfNeeded()
            }
        }
    }
    
    func setSelecting(selecting: Bool, animated: Bool) {
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationCurve(.EaseInOut)
            self.selecting = selecting
            UIView.commitAnimations()
        } else {
            self.selecting = selecting
        }
    }
    
    func selectMode(sender: FlashModeButton) {
        let mode = sender.mode
        self.mode = mode
        setSelecting(false, animated: true)
        sendActionsForControlEvents(.ValueChanged)
    }
    
    func changeMode(sender: UIButton) {
        setSelecting(true, animated: true)
    }
}
