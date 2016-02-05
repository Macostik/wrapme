//
//  SignupStepViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

enum SignupStepStatus: Int {
    case Success, Failure, Cancel, Verification, LinkDevice, UnconfirmedEmail
};

private struct SignupStepHandler {
    let block: Void -> SignupStepViewController?
}

class SignupStepViewController: WLBaseViewController {
    
    private var handlers = [SignupStepStatus : SignupStepHandler]()
    
    @IBOutlet weak var phoneLabel: UILabel!
    
    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneLabel?.text = Authorization.current.fullPhoneNumber
        emailLabel?.text = Authorization.current.email
    }
    
    override func keyboardAdjustmentForConstraint(constraint: NSLayoutConstraint!, defaultConstant: CGFloat, keyboardHeight: CGFloat) -> CGFloat {
        if let responder = view.findFirstResponder() {
            let responderCenterY = responder.center.y + 64
            let centerYOfVisibleSpace = (view.height - keyboardHeight - 64)/2 + 64
            return max(0, (responderCenterY - centerYOfVisibleSpace) * constraint.multiplier)
        }
        return Constants.isPhone ? keyboardHeight / 2 : 0
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if navigationController == nil {
            view = nil
        }
    }
    
    subscript(status: SignupStepStatus) -> (Void -> SignupStepViewController?)? {
        get { return handlers[status]?.block }
        set {
            if let handler = newValue {
                handlers[status] = SignupStepHandler(block: handler)
            } else {
                handlers[status] = nil
            }
        }
    }
    
    func setStatus(status: SignupStepStatus, animated: Bool) -> Bool {
        guard let handler = handlers[status] else { return false }
        if let navigationController = navigationController, let controller = handler.block() {
            if navigationController.viewControllers.contains(controller) {
                navigationController.popToViewController(controller, animated: animated)
            } else {
                navigationController.pushViewController(controller, animated: animated)
            }
        }
        return true
    }
    
    func setSuccessStatusAnimated(animated: Bool) -> Bool  {
        return setStatus(.Success, animated: animated)
    }
    
    func setFailureStatusAnimated(animated: Bool) -> Bool  {
        return setStatus(.Failure, animated: animated)
    }
    
    func setCancelStatusAnimated(animated: Bool) -> Bool  {
        return setStatus(.Cancel, animated: animated)
    }
    
    @IBAction func success(sender: AnyObject?) {
        setSuccessStatusAnimated(false)
    }
    
    @IBAction func failure(sender: AnyObject?) {
        setFailureStatusAnimated(false)
    }
    
    @IBAction func cancel(sender: AnyObject?) {
        if !setCancelStatusAnimated(false) {
            navigationController?.popViewControllerAnimated(false)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func configure( @noescape block: SignupStepViewController -> Void) -> Self {
        block(self)
        return self
    }
}
