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
    let storyboard: UIStoryboard
    func instantiate() -> T? {
        return storyboard.instantiateViewControllerWithIdentifier(identifier) as? T
    }
    func instantiate(@noescape block: T -> Void) -> T? {
        if let controller = instantiate() {
            block(controller)
            return controller
        } else {
            return nil
        }
    }
}

struct Storyboard {
    static let AddFriends = StoryboardObject<WLAddContributorsViewController>(identifier: "addFriends", storyboard: UIStoryboard.main())
    static let UploadWizardEnd = StoryboardObject<UploadWizardEndViewController>(identifier: "uploadWizardEnd", storyboard: UIStoryboard.main())
    static let LiveBroadcaster = StoryboardObject<LiveBroadcasterViewController>(identifier: "liveBroadcaster", storyboard: UIStoryboard.main())
}

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