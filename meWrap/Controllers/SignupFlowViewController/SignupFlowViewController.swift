//
//  SignupFlowViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class SignupFlowViewController: BaseViewController {
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var nextButton: UIButton!
    
    private var stepViewControllers = [SignupStepViewController]()
    
    private weak var flowNavigationController: UINavigationController!
    
    var registrationNotCompleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        flowNavigationController = childViewControllers.last as? UINavigationController
        flowNavigationController.delegate = self
        if registrationNotCompleted {
            completeSignup()
        } else {
            configureSignupFlow()
        }
    }
    
    private func stepViewController(identifier: String) -> SignupStepViewController? {
        if let controller = storyboard?[identifier] as? SignupStepViewController {
            stepViewControllers.append(controller)
            return controller
        } else {
            return nil
        }
    }
    
    private func completeSignup() {
        let profileStep = stepViewController("editProfile") as! EditProfileViewController
        profileStep[.Success] = {
            UIStoryboard.main.present(true)
            return nil
        }
        flowNavigationController.viewControllers = [profileStep]
    }
    
    func configureSignupFlow() {
        
        unowned let email = stepViewController("email") as! EmailViewController
        unowned let phone = stepViewController("phone") as! PhoneViewController
        unowned let verification = stepViewController("activation") as! ActivationViewController
        unowned let linkDevice = stepViewController("linkDevice") as! LinkDeviceViewController
        unowned let confirmEmail = stepViewController("confirmEmail") as! ConfirmEmailViewController
        unowned let verificationSuccess = stepViewController("verificationSuccess")!
        unowned let verificationFailure = stepViewController("verificationFailure")!
        unowned let linkDeviceSuccess = stepViewController("linkDeviceSuccess")!
        unowned let confirmEmailSuccess = stepViewController("emailConfirmationSuccess")!
        unowned let editProfile = stepViewController("editProfile") as! EditProfileViewController
        
        flowNavigationController.viewControllers = [email]
        // final completion block
        
        let completeSignUp = { () -> SignupStepViewController? in
            let storyboard = UIStoryboard.main
            if User.currentUser!.firstTimeUse {
                let navigation = storyboard.instantiateInitialViewController() as! UINavigationController
                let viewController: UIViewController! = storyboard["uploadWizard"]
                navigation.viewControllers = [navigation.viewControllers.first!, viewController]
                UIWindow.mainWindow.rootViewController = navigation
            } else {
                storyboard.present(false)
            }
            return nil
        }
        
        // profile subflow (will be skipped if is not required)
        
        let profileStepBlock = { () -> SignupStepViewController? in
            if User.currentUser!.isSignupCompleted {
                return completeSignUp()
            } else {
                return editProfile.configure { $0[.Success] = completeSignUp }
            }
        }
        
        // verification subflow
        
        let verify = { (seccessBlock: (() -> SignupStepViewController?), shouldSignIn: Bool) -> SignupStepViewController? in
            
            phone[.Success] = {
                verification[.Success] = {
                    return verificationSuccess.configure { $0[.Success] = { return seccessBlock() } }
                }
                verification[.Failure] = {
                    verificationFailure[.Failure] = { return verification }
                    verificationFailure[.Cancel] = { return phone }
                    return verificationFailure
                }
                verification.shouldSignIn = shouldSignIn
                return verification
            }
            
            phone[.Cancel] = { return email }
            return phone
        }
        
        // device linking subflow
        
        let linkDeviceBlock = { (shouldSendPasscode: Bool) -> SignupStepViewController? in
            linkDevice[.Success] = {
                return linkDeviceSuccess.configure { $0[.Success] = { return profileStepBlock() } }
            }
            if shouldSendPasscode {
                linkDevice.sendPasscode()
            }
            return linkDevice
        }
        
        
        // second device signup subflow (different for phone and wifi device)
        
        let secondDeviceBlock = { () -> SignupStepViewController? in
            if Telephony.hasPhoneNumber || !WhoIs.sharedInstance.containsPhoneDevice {
                return verify({ return linkDeviceBlock(false) }, false)
            } else {
                return linkDeviceBlock(true)
            }
        }
        
        // first sign up flow
        
        email[.Verification] = {
            return verify({ return profileStepBlock() }, true)
        }
        
        // second device witn unconfirmed e-mail flow
        
        email[.UnconfirmedEmail] = {
            return confirmEmail.configure { $0[.Success] = {
                return confirmEmailSuccess.configure { $0[.Success] = secondDeviceBlock }
                }
            }
        }
        
        // second device witn confirmed e-mail flow
        
        email[.LinkDevice] = secondDeviceBlock
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return flowNavigationController?.topViewController?.preferredStatusBarStyle() ?? .LightContent
    }
    
}

extension SignupFlowViewController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIView.performAnimated(animated) {
            headerView.alpha = viewController is SignupStepViewController ? 1 : 0
        }
    }
}
