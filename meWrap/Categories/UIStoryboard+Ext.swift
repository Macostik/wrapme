//
//  UIStoryboard+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIStoryboard {
    
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
    
    func push(controller: UIViewController, animated: Bool = false) {
        pushViewController(controller, animated: animated)
    }
}