//
//  Toast.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/5/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class Toast: UIView {
    
    static let DismissalDelay: NSTimeInterval = 4.0

    private static let toast: Toast = Toast.loadFromNib("Toast")!
    
    private static let defaultAppearance = Appearance()
    
    struct Appearance {
        var isIconHidden = false
        var backgroundColor = UIColor(hex: 0xcb5309, alpha: 1)
        var textColor = UIColor.whiteColor()
    }
    
    private let runQueue = RunQueue(limit: 1)
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var iconView: UIView!
    
    private weak var topViewConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var topMessageInset: NSLayoutConstraint!
    
    private var dismissBlock: Block?
    
    private var queuedMessages = Set<String>()
    
    private func applyAppearance(appearance: Appearance) {
        iconView.hidden = appearance.isIconHidden
        backgroundColor = appearance.backgroundColor
        messageLabel.textColor = appearance.textColor
    }
    
    class func show(message: String) {
        Toast.toast.show(message, inViewController: nil, appearance: nil)
    }
    
    func show(message: String, inViewController viewController: UIViewController?, appearance: Appearance?) {
    
        if message.isEmpty || (superview != nil && messageLabel.text == message) { return }
        
        queuedMessages.insert(message)
        
        weak var viewController = viewController ?? UIViewController.toastAppearanceViewController(self)
        
        let appearance = appearance ?? Toast.defaultAppearance

        runQueue.run { [unowned self] (finish) -> Void in
            guard let viewController = viewController else {
                self.queuedMessages.remove(message)
                finish()
                return
            }
            let view = viewController.view
            let referenceView = viewController.toastAppearanceReferenceView(self)
            
            self.applyAppearance(appearance)
            
            self.messageLabel.text = message
            
            if self.superview != view {
                self.removeFromSuperview()
                self.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(self)
                self.addConstraints(view, referenceView: referenceView)
                self.layoutIfNeeded()
                self.alpha = 0.0
                UIView.performAnimated(true) { self.alpha = 1.0 }
            }
            
            self.dismissBlock = {
                self.queuedMessages.remove(message)
                finish()
            }
            self.enqueueSelector("dismiss", delay: Toast.DismissalDelay)
        }
    }
    
    private func addConstraints(view: UIView, referenceView: UIView) {
        view.addConstraint(constraintToItem(referenceView, equal: .Width))
        view.addConstraint(constraintToItem(referenceView, equal: .CenterX))
        if referenceView == view {
            let topViewConstraint = constraintToItem(referenceView, equal: .Top)
            view.addConstraint(topViewConstraint)
            self.topViewConstraint = topViewConstraint;
            topMessageInset.constant = UIApplication.sharedApplication().statusBarHidden ? 6 : 26
        } else {
            let topViewConstraint = constraintForAttrbute(.Top, toItem: referenceView, equalToAttribute: .Bottom)
            view.addConstraint(topViewConstraint)
            self.topViewConstraint = topViewConstraint
            topMessageInset.constant = 6
        }
    }
    
    func dismiss() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "dismiss", object: nil)
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.alpha = 0
            }, completion: { (_) -> Void in
                self.removeFromSuperview()
                self.dismissBlock?()
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        dismiss()
    }
}

extension UIViewController {

    class func toastAppearanceViewController(toast: Toast) -> UIViewController? {
        var visibleViewController = UIWindow.mainWindow.rootViewController
        var presentedViewController = visibleViewController?.presentedViewController
        while let _presentedViewController = presentedViewController {
            if _presentedViewController.definesToastAppearance() {
                visibleViewController = presentedViewController
                presentedViewController = visibleViewController?.presentedViewController
            } else {
                presentedViewController = nil
            }
        }
        if let navigationController = visibleViewController as? UINavigationController {
            visibleViewController = navigationController.topViewController
        }
        return visibleViewController?.toastAppearanceViewController(toast)
    }
    
    func definesToastAppearance() -> Bool {
        return true
    }
        
    func toastAppearanceViewController(toast: Toast) -> UIViewController {
        return self
    }
            
    func toastAppearanceReferenceView(toast: Toast) -> UIView {
        if respondsToSelector("navigationBar") {
            return performSelector("navigationBar").takeUnretainedValue() as? UIView ?? view
        } else {
            return view
        }
    }

}

extension UIAlertController {
    override func definesToastAppearance() -> Bool {
        return false
    }
}

extension Toast {
    
    class func showDownloadingMediaMessageForCandy(candy: Candy?) {
        if let candy = candy where candy.valid {
            show(String(format: (candy.isVideo ? "downloading_video" : "downloading_photo").ls, Constants.albumName))
        } else {
            show(String(format: "downloading_media".ls, Constants.albumName))
        }
    }
    
    class func showMessageForUnavailableWrap(wrap: Wrap?) {
        show(String(format: "formatted_wrap_unavailable".ls, wrap?.name ?? ""))
    }
}
