//
//  Toast.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/5/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

protocol Appearance {
    var isIconHidden: Bool { get }
    var backgroundColor: UIColor  { get }
    var textColor: UIColor { get }
    
    func updateStyle()
}

protocol DefaultToastAppearance : Appearance {}
extension DefaultToastAppearance {
    var isIconHidden: Bool { return false }
    var backgroundColor: UIColor  { return UIColor.clearColor() }
    var textColor: UIColor { return UIColor.whiteColor() }
}

extension InfoToast: Appearance {
    func updateStyle() {
        leftIconView.hidden = isIconHidden
        backgroundColor = backgroundColor
        messageLabel.textColor = textColor
    }
}

class Toast: UIView {
    static let DismissalDelay: NSTimeInterval = 4.0
    
    func handleTouch() {}
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        handleTouch()
    }
    func dissmis() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(Toast.handleTouch), object: nil)
        UIView.animateWithDuration(0.25, animations: { self.alpha = 0 }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}

class InfoToast: Toast, DefaultToastAppearance {
    
    private static let toast = InfoToast()
    
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
        updateStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func show(message: String) {
        toast.show(message)
    }
    
    func show(message: String, inViewController viewController: UIViewController? = nil) {
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
            self.enqueueSelector(#selector(Toast.handleTouch), delay: Toast.DismissalDelay)
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
    
    override func handleTouch() {
        self.dismissBlock?()
        dissmis()
    }
}

class EntryToast: Toast {
    
    private var entry: Contribution!
    
    private let avatar = ImageView(backgroundColor: UIColor.clearColor())
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    private var topLabel = Label(preset: .Normal, weight: .Bold, textColor: UIColor.whiteColor())
    private let middleLabel = Label(preset: .Normal, weight: .Regular, textColor: UIColor.whiteColor())
    private let rightLabel = Label(preset: .Small, weight: .Regular, textColor: Color.orange)
    private let bottomView = View()
    private let bottomLabel = Label(preset: .Normal, weight: .Bold, textColor: UIColor.whiteColor())
    
    required init(entry: Contribution) {
        super.init(frame: CGRectZero)
        self.entry = entry
        backgroundColor = UIColor.blackColor()
        bottomView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        addSubview(avatar)
        addSubview(topLabel)
        addSubview(middleLabel)
        addSubview(rightLabel)
        addSubview(imageView)
        addSubview(bottomView)
        avatar.circled = true
        avatar.url = User.currentUser?.avatar?.small
        topLabel.numberOfLines = 0
        middleLabel.numberOfLines = 2
        topLabel.text = String(format:entry is Candy ?
                        "just_sent_you_a_new_photo".ls : "someone_commented".ls, entry.contributor?.name ?? "")
        if let comment = entry as? Comment {
            middleLabel.text = comment.text
        }
        rightLabel.text = "now".ls
        bottomLabel.text = "tap_to_view".ls
        imageView.url = entry.asset?.medium
        bottomView.addSubview(bottomLabel)
        
        avatar.snp_makeConstraints {
            $0.top.equalTo(self).offset(20)
            $0.leading.equalTo(self).offset(12)
            $0.size.equalTo(28)
        }
        
        topLabel.snp_makeConstraints {
            $0.leading.equalTo(avatar.snp_trailing).offset(12)
            $0.top.equalTo(avatar)
            $0.trailing.lessThanOrEqualTo(rightLabel.snp_leading).offset(-12)
        }
        
        middleLabel.snp_makeConstraints {
            $0.leading.equalTo(avatar.snp_trailing).offset(12)
            $0.top.equalTo(topLabel.snp_bottom)
            $0.trailing.lessThanOrEqualTo(rightLabel.snp_leading).offset(-12)
        }
        
        rightLabel.snp_makeConstraints {
            $0.trailing.equalTo(self).offset(-12)
            $0.centerY.equalTo(avatar)
        }
        rightLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        
        imageView.snp_makeConstraints {
            $0.top.equalTo(middleLabel.snp_bottom).offset(12)
            $0.leading.trailing.bottom.equalTo(self)
            $0.height.equalTo(Constants.screenWidth / 3 * 1.5)
        }
        
        bottomView.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(imageView)
        }
        
        bottomLabel.snp_makeConstraints { make in
            make.edges.equalTo(bottomView).inset(UIEdgeInsetsMake(8, 8, 8, 8))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(inViewController viewController: UIViewController? = nil) {
        weak var viewController = viewController ?? UIViewController.toastAppearanceViewController(self)
        guard let _viewController = viewController else { return }
        let view = _viewController.view
        if self.superview != view {
            self.removeFromSuperview()
            view.addSubview(self)
            snp_remakeConstraints {
                $0.width.centerX.equalTo(view)
                $0.top.equalTo(view)
            }
            self.layoutIfNeeded()
            self.alpha = 0.0
            UIView.performAnimated(true) { self.alpha = 1.0 }
        }
        self.enqueueSelector(#selector(Toast.dissmis), delay: Toast.DismissalDelay)
        SoundPlayer.player.play(.note)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    override func handleTouch() {
        ChronologicalEntryPresenter.presentEntry(entry, animated: false)
        dissmis()
    }
}

extension UIViewController {
    
    class func toastAppearanceViewController(toast: Toast?) -> UIViewController? {
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
    
    func toastAppearanceViewController(toast: Toast?) -> UIViewController {
        return self
    }
    
    func toastAppearanceReferenceView(toast: Toast) -> UIView {
        return view
    }
}

extension BaseViewController {
    
    override func toastAppearanceReferenceView(toast: Toast) -> UIView {
        return navigationBar ?? view
    }
}

extension UIAlertController {
    override func definesToastAppearance() -> Bool {
        return false
    }
}

extension InfoToast {
    
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
