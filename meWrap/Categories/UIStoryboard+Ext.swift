//
//  UIStoryboard+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIStoryboard {
    
    @nonobjc private static var _main = UIStoryboard(name: "Main", bundle: nil)
    
    class func main() -> UIStoryboard { return _main }
    
    @nonobjc private static var _signUp = UIStoryboard(name: "SignUp", bundle: nil)
    
    class func signUp() -> UIStoryboard { return _signUp }
    
    @nonobjc private static var _camera = UIStoryboard(name: "Camera", bundle: nil)
    
    class func camera() -> UIStoryboard { return _camera }
    
    @nonobjc private static var _introduction = UIStoryboard(name: "Introduction", bundle: nil)
    
    class func introduction() -> UIStoryboard { return _introduction }
    
    func present(animated: Bool) {
        UIWindow.mainWindow.rootViewController = instantiateInitialViewController()
    }
    
    subscript(key: String) -> UIViewController? {
        return instantiateViewControllerWithIdentifier(key)
    }
}

extension UIWindow {
    @nonobjc private static var _mainWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
    static var mainWindow: UIWindow { return _mainWindow }
}

extension UINavigationController {
    
    class func main() -> UINavigationController? {
        return UIWindow.mainWindow.rootViewController as? UINavigationController
    }
    
    public override func shouldAutorotate() -> Bool {
        guard let topViewController = topViewController else {
            return super.shouldAutorotate()
        }
        return topViewController.shouldAutorotate()
    }
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        guard let topViewController = topViewController else {
            return super.supportedInterfaceOrientations()
        }
        return topViewController.supportedInterfaceOrientations()
    }
}