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
    static let Friends = StoryboardObject<ContributorsViewController>("friends")
    static let UploadWizard = StoryboardObject<UploadWizardViewController>("uploadWizard")
    static let UploadWizardEnd = StoryboardObject<UploadWizardEndViewController>("uploadWizardEnd")
    static let LiveBroadcaster = StoryboardObject<LiveBroadcasterViewController>("liveBroadcaster")
    static let UploadSummary = StoryboardObject<UploadSummaryViewController>("uploadSummary", UIStoryboard.camera)
    static let WrapPicker = StoryboardObject<WrapPickerViewController>("wrapPicker", UIStoryboard.camera)
    static let ReportCandy = StoryboardObject<ReportViewController>("report")
    static let Comments = StoryboardObject<CommentsViewController>("comments")
    static let History = StoryboardObject<HistoryViewController>("history")
    static let HistoryItem = StoryboardObject<HistoryItemViewController>("historyItem")
    static let Countries = StoryboardObject<CountriesViewController>("countries", UIStoryboard.signUp)
    static let Wrap = StoryboardObject<WrapViewController>("wrap")
    static let WrapList = StoryboardObject<WrapListViewController>("wrapList")
    static let PhotoCandy = StoryboardObject<CandyViewController>("photoCandy")
    static let VideoCandy = StoryboardObject<CandyViewController>("videoCandy")
    static let SignupFlow = StoryboardObject<SignupFlowViewController>("signupFlow", UIStoryboard.signUp)
}

extension UIStoryboard {
    
    @nonobjc static var main = UIStoryboard(name: "Main", bundle: nil)
    @nonobjc static var signUp = UIStoryboard(name: "SignUp", bundle: nil)
    @nonobjc static var camera = UIStoryboard(name: "Camera", bundle: nil)
    @nonobjc static var introduction = UIStoryboard(name: "Introduction", bundle: nil)
    
    func present(animated: Bool) {
        UIWindow.mainWindow.rootViewController = instantiateInitialViewController()
        if #available(iOS 9.0, *) {} else {
            UIWindow.mainWindow.frame = UIScreen.mainScreen().bounds
            UIWindow.mainWindow.rootViewController?.view.frame = UIScreen.mainScreen().bounds
        }
    }
    
    subscript(key: String) -> UIViewController? {
        return instantiateViewControllerWithIdentifier(key)
    }
}

extension UIWindow {
    @nonobjc static var mainWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
}

extension UINavigationController {
    
    class func main() -> UINavigationController? {
        return UIWindow.mainWindow.rootViewController as? UINavigationController
    }
    
    public override func shouldAutorotate() -> Bool {
        return topViewController?.shouldAutorotate() ?? super.shouldAutorotate()
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations() ?? super.supportedInterfaceOrientations()
    }
}