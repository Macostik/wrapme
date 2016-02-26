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
    var storyboard: UIStoryboard = UIStoryboard.main()
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
    static let AddFriends = StoryboardObject<AddContributorsViewController>(identifier: "addFriends", storyboard: UIStoryboard.main())
    static let Friends = StoryboardObject<ContributorsViewController>(identifier: "friends", storyboard: UIStoryboard.main())
    static let UploadWizard = StoryboardObject<UploadWizardViewController>(identifier: "uploadWizard", storyboard: UIStoryboard.main())
    static let UploadWizardEnd = StoryboardObject<UploadWizardEndViewController>(identifier: "uploadWizardEnd", storyboard: UIStoryboard.main())
    static let LiveBroadcaster = StoryboardObject<LiveBroadcasterViewController>(identifier: "liveBroadcaster", storyboard: UIStoryboard.main())
    static let UploadSummary = StoryboardObject<UploadSummaryViewController>(identifier: "uploadSummary", storyboard: UIStoryboard.camera())
    static let WrapPicker = StoryboardObject<WrapPickerViewController>(identifier: "wrapPicker", storyboard: UIStoryboard.camera())
    static let ReportCandy = StoryboardObject<ReportViewController>(identifier: "report", storyboard: UIStoryboard.main())
    static let Comments = StoryboardObject<CommentsViewController>(identifier: "comments", storyboard: UIStoryboard.main())
    static let History = StoryboardObject<HistoryViewController>(identifier: "history", storyboard: UIStoryboard.main())
    static let HistoryItem = StoryboardObject<HistoryItemViewController>(identifier: "historyItem", storyboard: UIStoryboard.main())
    static let Countries = StoryboardObject<CountriesViewController>(identifier: "countries", storyboard: UIStoryboard.signUp())
    static let Wrap = StoryboardObject<WrapViewController>(identifier: "wrap", storyboard: UIStoryboard.main())
    static let WrapList = StoryboardObject<WrapListViewController>(identifier: "wrapList", storyboard: UIStoryboard.main())
    static let Candy = StoryboardObject<CandyViewController>(identifier: "candy", storyboard: UIStoryboard.main())
    static let SignupFlow = StoryboardObject<SignupFlowViewController>(identifier: "signupFlow", storyboard: UIStoryboard.signUp())
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