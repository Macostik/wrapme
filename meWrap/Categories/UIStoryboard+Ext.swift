//
//  UIStoryboard+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIStoryboard {
    
    @nonobjc private static weak var _main = UIStoryboard(name: "Main", bundle: nil)
    
    class func main() -> UIStoryboard? {
        return _main
    }
    
    @nonobjc private static weak var _signUp = UIStoryboard(name: "SignUp", bundle: nil)
    
    class func signUp() -> UIStoryboard? {
        return _signUp
    }
    
    @nonobjc private static weak var _camera = UIStoryboard(name: "Camera", bundle: nil)
    
    class func camera() -> UIStoryboard? {
        return _camera
    }
    
    @nonobjc private static weak var _introduction = UIStoryboard(name: "Introduction", bundle: nil)
    
    class func introduction() -> UIStoryboard? {
        return _introduction
    }
    
    func present(animated: Bool) {
        UIWindow.mainWindow?.rootViewController = instantiateInitialViewController()
    }
    
    subscript(key: String) -> AnyObject? {
        get {
            return instantiateViewControllerWithIdentifier(key)
        }
    }
}

extension UIWindow {
    @nonobjc private static var _mainWindow: UIWindow?
    static var mainWindow: UIWindow? {
        get {
            return _mainWindow
        }
        set {
            _mainWindow = newValue
        }
    }
}