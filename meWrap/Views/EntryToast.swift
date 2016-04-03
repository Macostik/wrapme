//
//  EntryToast.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/03/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class EntryToast: UIView {
    static let entryToast = EntryToast()
    static let DismissalDelay: NSTimeInterval = 4.0
    private let imageHeight = Constants.screenWidth / 3 * 1.5
    private var entry: Entry?
    private let avatar = ImageView(backgroundColor: UIColor.clearColor())
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    private var topLabel = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let middleLabel = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    private let rightLabel = Label(preset: .Smaller, weight: .Regular, textColor: Color.orange)
    private let bottomLabel = Label(preset: .Smaller, weight: .Regular, textColor: UIColor.whiteColor())
    private let liveBadge = Label(preset: .Small, textColor: UIColor.whiteColor())
    private let topView = View()
    private let bottomView = View()
    var topViewBottomCostraint: Constraint?
    var imageBottomCostraint: Constraint?
    var imageHeightCostraint: Constraint?
    var handleTouch: ObjectBlock?
    
    required init() {
        super.init(frame: CGRectZero)
        
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
    
    func setup(entry: Entry) {
        self.entry = entry
        avatar.circled = true
        if let wrap = entry as? Wrap where wrap.liveBroadcasts.isEmpty == false {
           avatar.url = wrap.liveBroadcasts.last?.broadcaster?.avatar?.small
        } else if let wrap = entry as? Wrap where wrap.inviter != nil {
            avatar.url = wrap.inviter?.avatar?.small
        } else if let entry = entry as? Contribution {
           avatar.url = entry.contributor?.avatar?.small
        }
        topLabel.numberOfLines = 0
        middleLabel.numberOfLines = 2
        rightLabel.text = "now".ls
        bottomLabel.text = "tap_to_view".ls
        imageView.defaultIconText = "t"
        imageView.defaultIconColor = Color.grayLighter
        imageView.defaultBackgroundColor = UIColor.whiteColor()
        if let _entry = entry as? Contribution {
            imageView.url = _entry.asset?.medium
        }
        liveBadge.textAlignment = .Center
        liveBadge.cornerRadius = 8
        liveBadge.clipsToBounds = true
        liveBadge.backgroundColor = Color.dangerRed
        liveBadge.text = "LIVE"
        showBadge(false)
        setupContent(entry)
        SoundPlayer.player.play(.note)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    private func setupContent(entry: Entry) {
        switch entry {
        case let candy as Candy:
            if candy.editor != nil {
                topLabel.text = String(format: "someone_edited_photo".ls, candy.editor?.name ?? "")
            } else {
                topLabel.text = String(format:  candy.isVideo ?
                    "just_sent_you_a_new_video".ls :
                    "just_sent_you_a_new_photo".ls, candy.contributor?.name ?? "")
            }
            middleLabel.text = ""
            fullStyle()
            break
        case let comment as Comment:
            topLabel.text = String(format: "someone_commented".ls, comment.contributor?.name ?? "")
            middleLabel.text = comment.text
            fullStyle()
            break
        case let message as Message:
            topLabel.text = String(format: "\(message.contributor?.name ?? ""):")
            middleLabel.text = message.text
            shortStyle()
            break
        case let wrap as Wrap where wrap.liveBroadcasts.isEmpty == false:
            topLabel.text = String(format: "someone_is_live".ls, wrap.contributor?.name ?? "")
            middleLabel.text = String(format: "\(wrap.name ?? "")")
            showBadge(true)
            shortStyle()
            break
        case let wrap as Wrap where wrap.inviter != nil:
            topLabel.text =  String(format: "you're_invited".ls ?? "")
            middleLabel.text = String(format: "invited_you_to".ls, wrap.inviter?.name ?? "", wrap.name ?? "")
            fullStyle()
            break
            
        default:break
        }
    }
    
    func show(inViewController viewController: UIViewController? = nil) {
        let _window = UIWindow.mainWindow
        _window.windowLevel = UIWindowLevelStatusBar
        if self.superview != _window {
            self.removeFromSuperview()
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
        
        self.enqueueSelector(#selector(EntryToast.dissmis), delay: EntryToast.DismissalDelay)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        dissmis()
        UIWindow.mainWindow.endEditing(true)
        guard let entry = entry else { return }
        guard let nc = UINavigationController.main() else { return }
        if let liveVC = nc.topViewController as? LiveBroadcasterViewController {
            liveVC.close()
        }
        ChronologicalEntryPresenter.presentEntry(entry, animated: false)
        if let wrap = entry as? Wrap where wrap.liveBroadcasts.isEmpty == false {
            if let controller = wrap.viewControllerWithNavigationController(nc) as? WrapViewController {
                guard let liveBroadcast = wrap.liveBroadcasts.last else { return }
                controller.presentLiveBroadcast(liveBroadcast)
            }
        }
        handleTouch?(self)
    }
    
    func dissmis() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(EntryToast.touchesBegan(_:withEvent:)), object: nil)
        UIView.animateWithDuration(0.5, animations: {
            self.transform = CGAffineTransformIdentity
            }, completion: { _ in
                self.removeFromSuperview()
                UIWindow.mainWindow.windowLevel = UIWindowLevelNormal
        })
    }
    
    private func showBadge(show: Bool) {
        liveBadge.snp_updateConstraints {
            $0.centerY.equalTo(topLabel)
            $0.height.equalTo(20)
            if show {
                $0.leading.equalTo(avatar.snp_trailing).offset(12)
                $0.width.equalTo(40)
            } else {
                $0.leading.equalTo(avatar.snp_trailing)
                $0.width.equalTo(0)
            }
        }
    }
    
    private func shortStyle() {
        topViewBottomCostraint?.activate()
        imageBottomCostraint?.deactivate()
        imageHeightCostraint?.updateOffset(0)
    }
    
    private func fullStyle() {
        topViewBottomCostraint?.deactivate()
        imageBottomCostraint?.activate()
        imageHeightCostraint?.updateOffset(imageHeight)
    }
}

extension Entry {
    func showToast() {
        let entryToast = EntryToast.entryToast
        entryToast.setup(self)
        entryToast.show()
    }
}

