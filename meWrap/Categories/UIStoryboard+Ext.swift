//
//  UIStoryboard+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

struct StoryboardObject<T: UIViewController> {
    let identifier: String
    var storyboard: UIStoryboard
    init(_ identifier: String, _ storyboard: UIStoryboard = UIStoryboard.main) {
        self.identifier = identifier
        self.storyboard = storyboard
    }
    func instantiate() -> T {
        return storyboard.instantiateViewControllerWithIdentifier(identifier) as! T
    }
    func instantiate(@noescape block: T -> Void) -> T {
        let controller = instantiate()
        block(controller)
        return controller
    }
}

struct Storyboard {
    static let AddFriends = StoryboardObject<AddContributorsViewController>("addFriends")
    static let UploadWizard = StoryboardObject<UploadWizardViewController>("uploadWizard")
    static let UploadWizardEnd = StoryboardObject<UploadWizardEndViewController>("uploadWizardEnd")
    static let SignupFlow = StoryboardObject<SignupFlowViewController>("signupFlow", UIStoryboard.signUp)
}

extension UIStoryboard {
    
    @nonobjc static let main = UIStoryboard(name: "Main", bundle: nil)
    @nonobjc static let signUp = UIStoryboard(name: "SignUp", bundle: nil)
    @nonobjc static let introduction = UIStoryboard(name: "Introduction", bundle: nil)
    
    func present(animated: Bool) {
        UINavigationController.main.viewControllers = [instantiateInitialViewController()!]
    }
    
    subscript(key: String) -> UIViewController? {
        return instantiateViewControllerWithIdentifier(key)
    }
}

extension UIWindow {
    @nonobjc static let mainWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
}

extension UINavigationController {
    
    @nonobjc static let main = specify(UINavigationController()) {
        UIWindow.mainWindow.rootViewController = $0
        $0.navigationBarHidden = true
    }
    
    public override func shouldAutorotate() -> Bool {
        return topViewController?.shouldAutorotate() ?? super.shouldAutorotate()
    }
        
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations() ?? super.supportedInterfaceOrientations()
    }
}