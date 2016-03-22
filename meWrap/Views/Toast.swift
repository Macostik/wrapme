//
//  Toast.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/5/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

final class Toast: UIView {
    
    static let DismissalDelay: NSTimeInterval = 4.0
    
    private static let toast = Toast()
    
    private static let defaultAppearance = Appearance()
    
    struct Appearance {
        var isIconHidden = false
        var backgroundColor = UIColor.clearColor()
        var textColor = UIColor.whiteColor()
    }
    
    private let runQueue = RunQueue(limit: 1)
    
    private let messageLabel = Label(preset: .Small, weight: UIFontWeightRegular, textColor: UIColor.whiteColor())
    
    private let leftIconView = Label(icon: "Z", size: 21)
    
    private let rightIconView = Label(icon: "!", size: 17)
    
    private var topMessageInset: Constraint!
    
    private var dismissBlock: Block?
    
    private var queuedMessages = Set<String>()
    
    required init() {
        super.init(frame: CGRect.zero)
        leftIconView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        rightIconView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        messageLabel.numberOfLines = 2
        let blurEffect = UIBlurEffect(style: .Dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark)))
        addSubview(blurView)
        blurView.contentView.addSubview(vibrancyView)
        vibrancyView.contentView.addSubview(leftIconView)
        vibrancyView.contentView.addSubview(messageLabel)
        vibrancyView.contentView.addSubview(rightIconView)
        blurView.snp_makeConstraints { $0.edges.equalTo(self) }
        vibrancyView.snp_makeConstraints { $0.edges.equalTo(self) }
        leftIconView.snp_makeConstraints {
            $0.leading.equalTo(self).offset(12)
            $0.trailing.equalTo(messageLabel.snp_leading).offset(-12)
            $0.centerY.equalTo(messageLabel)
        }
        messageLabel.snp_makeConstraints {
            topMessageInset = $0.top.equalTo(self).inset(10).constraint
            $0.bottom.equalTo(self).inset(10)
            $0.trailing.lessThanOrEqualTo(rightIconView.snp_leading).offset(-12)
            $0.height.greaterThanOrEqualTo(21)
        }
        rightIconView.snp_makeConstraints {
            $0.trailing.equalTo(self).inset(12)
            $0.centerY.equalTo(messageLabel)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func applyAppearance(appearance: Appearance) {
        leftIconView.hidden = appearance.isIconHidden
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
            self.enqueueSelector(#selector(Toast.dismiss), delay: Toast.DismissalDelay)
        }
    }
    
    private func addConstraints(view: UIView, referenceView: UIView) {
        snp_remakeConstraints {
            $0.width.centerX.equalTo(referenceView)
            if referenceView == view {
                $0.top.equalTo(referenceView)
                topMessageInset.updateOffset(UIApplication.sharedApplication().statusBarHidden ? 10 : 30)
            } else {
                $0.top.equalTo(referenceView.snp_bottom)
                topMessageInset.updateOffset(10)
            }
        }
    }
    
    func dismiss() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(Toast.dismiss), object: nil)
        UIView.animateWithDuration(0.25, animations: { self.alpha = 0 }, completion: { (_) -> Void in
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
        if respondsToSelector(Selector("navigationBar")) {
            return performSelector(Selector("navigationBar"))?.takeUnretainedValue() as? UIView ?? view
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
