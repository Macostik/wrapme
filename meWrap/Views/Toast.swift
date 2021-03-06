//
//  Toast.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/5/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit
import Social

protocol Appearance {
    var isIconHidden: Bool { get }
    var backgroundColor: UIColor  { get }
    var textColor: UIColor { get }
}

struct DefaultToastAppearance : Appearance {
    var isIconHidden: Bool { return false }
    var backgroundColor: UIColor  { return UIColor.clearColor() }
    var textColor: UIColor { return UIColor.whiteColor() }
}

class Toast: UIView {
    
    static let DismissalDelay: NSTimeInterval = 4.0
    private static let toast = Toast()
    var topMessageInset: Constraint!
    var runQueue = RunQueue(limit: 1)
    var queuedMessages = Set<String>()
    var leftIconView = Label(icon: "Z", size: 21)
    var rightIconView = Label(icon: "!", size: 17)
    var messageLabel = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    var dismissBlock: Block?
    
    required init() {
        super.init(frame: CGRect.zero)
        leftIconView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        rightIconView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        messageLabel.numberOfLines = 2
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        addSubview(blurView)
        blurView.snp_makeConstraints { $0.edges.equalTo(self) }
        let colorView = UIView()
        colorView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        addSubview(colorView)
        colorView.snp_makeConstraints { $0.edges.equalTo(self) }
        addSubview(leftIconView)
        addSubview(messageLabel)
        addSubview(rightIconView)
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
    
    class func show(message: String) {
        toast.show(message)
    }
    
    func show(message: String, inViewController viewController: UIViewController? = nil, appearence: Appearance = DefaultToastAppearance()) {
        if message.isEmpty || (superview != nil && messageLabel.text == message) { return }
        
        queuedMessages.insert(message)
        
        weak var viewController = viewController ?? UIViewController.toastAppearanceViewController(self)
        
        runQueue.run { [unowned self] (finish) -> Void in
            guard let viewController = viewController else {
                self.queuedMessages.remove(message)
                finish()
                return
            }
            let view = viewController.view
            let referenceView = viewController.toastAppearanceReferenceView(self)
            
            self.messageLabel.text = message
            self.leftIconView.hidden = appearence.isIconHidden
            self.backgroundColor = appearence.backgroundColor
            self.messageLabel.textColor = appearence.textColor
            
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
    
    private func addConstraints( view: UIView, referenceView: UIView) {
        snp_remakeConstraints {
            $0.width.centerX.equalTo(referenceView)
            if referenceView == view  {
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
    
    class func toastAppearanceViewController(toast: UIView?) -> UIViewController? {
        var visibleViewController: UIViewController? = UINavigationController.main
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
    
    func toastAppearanceViewController(toast: UIView?) -> UIViewController {
        return self
    }
    
    func toastAppearanceReferenceView(toast: UIView) -> UIView {
        return view
    }
}

extension BaseViewController {
    
    override func toastAppearanceReferenceView(toast: UIView) -> UIView {
        return navigationBar ?? view
    }
}

extension UIAlertController {
    override func definesToastAppearance() -> Bool {
        return false
    }
}

extension UIActivityViewController {
    
    override func definesToastAppearance() -> Bool {
        return false
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    public override func shouldAutorotate() -> Bool {
        return false
    }
}

extension SLComposeViewController {
    
    override func definesToastAppearance() -> Bool {
        return false
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    public override func shouldAutorotate() -> Bool {
        return false
    }
}

extension Toast {
    
    static func downloadingMediaMessageForCandy(candy: Candy?) -> String {
        if let candy = candy where candy.valid {
            return String(format: (candy.isVideo ? "downloading_video" : "downloading_photo").ls, Constants.albumName)
        } else {
            return String(format: "downloading_media".ls, Constants.albumName)
        }
    }
    
    static func showDownloadingMediaMessageForCandy(candy: Candy?) {
        show(downloadingMediaMessageForCandy(candy))
    }
    
    static func showMessageForUnavailableWrap(wrap: Wrap?) {
        show(String(format: "formatted_wrap_unavailable".ls, wrap?.name ?? ""))
    }
}
