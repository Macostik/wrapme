//
//  EntryToast.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/03/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

enum EntryToastStyle {
    case Full, Short
}

class EntryToast: UIView {
    static let entryToast = EntryToast()
    static let DismissalDelay: NSTimeInterval = 4.0
    private let imageHeight = Constants.screenWidth / 3 * 1.5
    private let avatar = ImageView(backgroundColor: UIColor.clearColor())
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    private var topLabel = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let middleLabel = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    private let rightLabel = Label(preset: .Smaller, weight: .Regular, textColor: Color.orange)
    private let bottomLabel = Label(preset: .Smaller, weight: .Regular, textColor: UIColor.whiteColor())
    private lazy var liveBadge = Label(preset: .Small, textColor: UIColor.whiteColor())
    private let topView = View()
    private let bottomView = View()
    var topViewBottomCostraint: Constraint?
    var imageBottomCostraint: Constraint?
    var imageHeightCostraint: Constraint?
    var handleTouch: (() -> ())?
    
    required init() {
        super.init(frame: CGRectZero)
        liveBadge.textAlignment = .Center
        liveBadge.cornerRadius = 8
        liveBadge.clipsToBounds = true
        liveBadge.backgroundColor = Color.dangerRed
        liveBadge.text = "LIVE"
        topLabel.numberOfLines = 0
        middleLabel.numberOfLines = 2
        rightLabel.text = "now".ls
        bottomLabel.text = "tap_to_view".ls
        avatar.cornerRadius = 14
        imageView.defaultIconText = "t"
        imageView.defaultIconColor = Color.grayLighter
        imageView.defaultBackgroundColor = UIColor.whiteColor()
        backgroundColor = UIColor.blackColor()
        topView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        bottomView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        addSubview(imageView)
        addSubview(topView)
        addSubview(bottomView)
        topView.addSubview(avatar)
        topView.addSubview(liveBadge)
        topView.addSubview(topLabel)
        topView.addSubview(middleLabel)
        topView.addSubview(rightLabel)
        bottomView.addSubview(bottomLabel)
        
        topView.snp_makeConstraints {
            $0.top.leading.trailing.equalTo(self)
            topViewBottomCostraint = $0.bottom.equalTo(self).constraint
        }
        
        avatar.snp_makeConstraints {
            $0.centerY.equalTo(topLabel)
            $0.leading.equalTo(topView).offset(12)
            $0.size.equalTo(28)
        }
        
        topLabel.snp_makeConstraints {
            $0.leading.equalTo(liveBadge.snp_trailing).offset(12)
            $0.top.equalTo(topView).offset(12)
            $0.trailing.lessThanOrEqualTo(rightLabel.snp_leading).offset(-12)
        }
        
        liveBadge.snp_makeConstraints {
            $0.centerY.equalTo(topLabel)
            $0.height.equalTo(20)
            $0.leading.equalTo(avatar.snp_trailing)
            $0.width.equalTo(0)
        }
        
        middleLabel.snp_makeConstraints {
            $0.leading.equalTo(avatar.snp_trailing).offset(12)
            $0.top.equalTo(topLabel.snp_bottom)
            $0.trailing.lessThanOrEqualTo(rightLabel.snp_leading).offset(-12)
            $0.bottom.equalTo(topView).offset(-12)
        }
        
        rightLabel.snp_makeConstraints {
            $0.centerY.equalTo(topLabel)
            $0.trailing.equalTo(topView).offset(-12)
        }
        rightLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        
        imageView.snp_makeConstraints {
            $0.top.leading.trailing.equalTo(self)
            imageHeightCostraint = $0.height.equalTo(imageHeight).constraint
            imageBottomCostraint = $0.bottom.equalTo(self).constraint
        }
        
        bottomView.snp_makeConstraints {
            $0.leading.trailing.equalTo(self)
            $0.bottom.equalTo(imageView)
        }
        
        bottomLabel.snp_makeConstraints {
            $0.edges.equalTo(bottomView).inset(UIEdgeInsetsMake(8, 8, 8, 8))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(style style: EntryToastStyle = .Full, @noescape setup: EntryToast -> (), handleTouch: (() -> ())? = nil) {
        guard UIApplication.sharedApplication().applicationState == .Active else { return }
        showBadge(false)
        Sound.play(.note)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        setup(self)
        self.handleTouch = handleTouch
        if style == .Full {
            topViewBottomCostraint?.deactivate()
            imageBottomCostraint?.activate()
            imageHeightCostraint?.updateOffset(imageHeight)
        } else {
            topViewBottomCostraint?.activate()
            imageBottomCostraint?.deactivate()
            imageHeightCostraint?.updateOffset(0)
        }
        let _window = UIWindow.mainWindow
        _window.windowLevel = UIWindowLevelStatusBar
        if self.superview != _window {
            _window.addSubview(self)
            snp_makeConstraints {
                $0.width.centerX.equalTo(_window)
                $0.bottom.equalTo(_window.snp_top)
            }
        }
        layoutIfNeeded()
        UIView.animateWithDuration(0.5, animations: {
            self.transform = CGAffineTransformMakeTranslation(0, self.height)
        })
        
        self.enqueueSelector(#selector(self.dissmis), delay: EntryToast.DismissalDelay)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        dissmis()
        UIWindow.mainWindow.endEditing(true)
        handleTouch?()
    }
    
    func dissmis() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(self.dissmis), object: nil)
        UIView.animateWithDuration(0.5, animations: {
            self.transform = CGAffineTransformIdentity
            }, completion: { _ in
                self.removeFromSuperview()
                UIWindow.mainWindow.windowLevel = UIWindowLevelNormal
        })
    }
    
    private func showBadge(show: Bool) {
        liveBadge.snp_updateConstraints {
            $0.leading.equalTo(avatar.snp_trailing).offset(show ? 12 : 0)
            $0.width.equalTo(show ? 40 : 0)
        }
    }
}

extension EntryToast {
    
    class func showCandyAddition(candy: Candy) {
        EntryToast.entryToast.show(setup: { (toast) in
            toast.avatar.url = candy.contributor?.avatar?.small
            toast.imageView.url = candy.asset?.medium
            toast.topLabel.text = String(format: (candy.isVideo ? "just_sent_you_a_new_video" : "just_sent_you_a_new_photo").ls, candy.contributor?.name ?? "")
            toast.middleLabel.text = ""
            }, handleTouch: { ChronologicalEntryPresenter.presentEntry(candy, animated: false) })
    }
    
    class func showCandyUpdate(candy: Candy) {
        EntryToast.entryToast.show(setup: { (toast) in
            toast.avatar.url = candy.contributor?.avatar?.small
            toast.imageView.url = candy.asset?.medium
            toast.topLabel.text = String(format: "someone_edited_photo".ls, candy.editor?.name ?? "")
            toast.middleLabel.text = ""
            }, handleTouch: { ChronologicalEntryPresenter.presentEntry(candy, animated: false) })
    }
    
    class func showCommentAddition(comment: Comment) {
        EntryToast.entryToast.show(setup: { (toast) in
            toast.avatar.url = comment.contributor?.avatar?.small
            toast.imageView.url = comment.asset?.medium
            toast.topLabel.text = String(format: "someone_commented".ls, comment.contributor?.name ?? "")
            toast.middleLabel.text = comment.text
            }, handleTouch: { ChronologicalEntryPresenter.presentEntry(comment, animated: false) })
    }
    
    class func showMessageAddition(message: Message) {
        EntryToast.entryToast.show(style: .Short, setup: { (toast) in
            toast.avatar.url = message.contributor?.avatar?.small
            toast.imageView.url = message.asset?.medium
            toast.topLabel.text = String(format: "\(message.contributor?.name ?? ""):")
            toast.middleLabel.text = message.text
            }, handleTouch: { ChronologicalEntryPresenter.presentEntry(message, animated: false) })
    }
    
    class func showWrapInvitation(wrap: Wrap, inviter: User?) {
        EntryToast.entryToast.show(style: wrap.asset?.medium == nil ? .Short : .Full, setup: { (toast) in
            toast.imageView.url = wrap.asset?.medium
            toast.avatar.url = inviter?.avatar?.small
            toast.topLabel.text =  String(format: "you're_invited".ls ?? "")
            toast.middleLabel.text = String(format: "invited_you_to".ls, inviter?.name ?? "", wrap.name ?? "")
            }, handleTouch: { ChronologicalEntryPresenter.presentEntry(wrap, animated: false) })
    }
    
    class func showLiveBroadcast(liveBroadcast: LiveBroadcast) {
        guard let wrap = liveBroadcast.wrap else { return }
        EntryToast.entryToast.show(style: .Short, setup: { (toast) in
            toast.imageView.url = wrap.asset?.medium
            toast.avatar.url = liveBroadcast.broadcaster?.avatar?.small
            toast.topLabel.text = String(format: "someone_is_live".ls, liveBroadcast.broadcaster?.name ?? "")
            toast.middleLabel.text = String(format: "\(wrap.name ?? "")")
            toast.showBadge(true)
        }) {
            ChronologicalEntryPresenter.presentEntry(wrap, animated: false)
            guard let nc = UINavigationController.main() else { return }
            (nc.topViewController as? LiveBroadcasterViewController)?.close()
            if let controller = wrap.viewControllerWithNavigationController(nc) as? WrapViewController {
                controller.presentLiveBroadcast(liveBroadcast)
            }
        }
    }
}

