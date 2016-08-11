//
//  NewWrapCreatedViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 7/19/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class NewWrapCreatedViewController: BaseViewController, EntryNotifying {
        
    internal let backgroundImageView = UIImageView()
    
    private let avatar = UserAvatarView(cornerRadius: 30, backgroundColor: UIColor.clearColor(), placeholderSize: 24)
    
    var wrap: Wrap?
    
    var p2p = false
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = Color.grayDarker
        
        let titleLabel = Label(preset: .Large, weight: .Semibold, textColor: UIColor.whiteColor())
        titleLabel.numberOfLines = 0
        let name = "\(p2p ? "@" : "")\(wrap?.name ?? "")"
        let title = String(format: "f_wrap_created_congratulations".ls, name)
        let titleText = NSMutableAttributedString(string: title, attributes: [NSFontAttributeName: Font.Large + .Semibold, NSForegroundColorAttributeName: UIColor.whiteColor()])
        titleText.addAttributes([NSFontAttributeName: UIFont.lightFontLarge(), NSForegroundColorAttributeName: Color.orange], range: (title as NSString).rangeOfString(name))
        titleLabel.attributedText = titleText
        
        if p2p {
            
            let contentView = UIView()
            view.add(contentView) { (make) in
                make.leading.trailing.equalTo(view)
                make.centerY.equalTo(view).offset(10)
                make.height.equalTo(view).offset(-148)
            }
            
            var size: CGSize = UIScreen.mainScreen().bounds.size.width ^ (UIScreen.mainScreen().bounds.height - 148)
            var mask = CAShapeLayer()
            var path = UIBezierPath()
            path.move(0 ^ 0)
            path.addCurveToPoint(size.width ^ 0, controlPoint1: (size.width * 0.25) ^ 12, controlPoint2: (size.width * 0.75) ^ 12)
            path.line(size.width ^ size.height)
            path.addCurveToPoint(0 ^ size.height, controlPoint1: (size.width * 0.75) ^ (size.height - 12), controlPoint2: (size.width * 0.25) ^ (size.height - 12))
            path.line(0 ^ 0)
            mask.path = path.CGPath
            contentView.layer.mask = mask
            
            let background = UIImageView(image: UIImage(named: "p2p_background"))
            background.contentMode = .ScaleAspectFill
            contentView.add(background, { (make) in
                make.leading.top.trailing.equalTo(contentView)
            })
            
            let actionsView = UIView()
            actionsView.backgroundColor = UIColor.whiteColor()
            contentView.add(actionsView, { (make) in
                make.leading.bottom.trailing.equalTo(contentView)
                make.top.equalTo(background.snp_bottom).offset(-20)
                make.height.equalTo(contentView).dividedBy(2)
            })
            size = UIScreen.mainScreen().bounds.size.width ^ size.height/2
            mask = CAShapeLayer()
            path = UIBezierPath()
            path.move(0 ^ 10)
            path.addCurveToPoint(size.width ^ 10, controlPoint1: (size.width * 0.25) ^ -2, controlPoint2: (size.width * 0.75) ^ -2)
            path.line(size.width ^ size.height).line(0 ^ size.height).line(0 ^ 10)
            mask.path = path.CGPath
            actionsView.layer.mask = mask
            
            contentView.add(avatar, { (make) in
                make.centerX.equalTo(contentView)
                make.top.equalTo(actionsView).offset(-16)
                make.size.equalTo(60)
            })
            if let invitee = wrap?.invitees.first {
                avatar.user = invitee.user
            } else {
                avatar.user = wrap?.contributors.filter({ !$0.current }).first
            }
            Wrap.notifier().addReceiver(self)
            
            titleLabel.numberOfLines = 2
            titleLabel.textAlignment = .Center
            view.add(titleLabel) { (make) in
                make.top.equalTo(view).offset(20)
                make.leading.trailing.equalTo(view).inset(12)
                make.bottom.equalTo(contentView.snp_top)
            }
            
            let messageLabel = Label(preset: .Large, weight: .Semibold, textColor: UIColor.whiteColor())
            messageLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Vertical)
            let message = String(format: "f_send_photo_video_to_wrap_now".ls, name)
            messageLabel.numberOfLines = 0
            let messageText = NSMutableAttributedString(string: message, attributes: [NSFontAttributeName: Font.Large + .Semibold, NSForegroundColorAttributeName: Color.grayDarker])
            messageText.addAttributes([NSFontAttributeName: UIFont.lightFontLarge(), NSForegroundColorAttributeName: Color.orange], range: (message as NSString).rangeOfString(name))
            messageLabel.attributedText = messageText
            messageLabel.numberOfLines = 2
            messageLabel.textAlignment = .Center
            contentView.add(messageLabel) { (make) in
                make.top.equalTo(avatar.snp_bottom).offset(20)
                make.centerX.equalTo(contentView)
                make.leading.greaterThanOrEqualTo(contentView).offset(12)
                make.trailing.lessThanOrEqualTo(contentView).offset(-12)
            }
            
            let photoButton = Button(icon: "u", size: 32)
            photoButton.clipsToBounds = true
            photoButton.addTarget(self, touchUpInside: #selector(self.addPhoto))
            photoButton.cornerRadius = 32
            photoButton.backgroundColor = Color.orange
            photoButton.highlightedColor = Color.orangeDark
            
            let videoButton = Button(icon: "+", size: 36)
            videoButton.clipsToBounds = true
            videoButton.addTarget(self, touchUpInside: #selector(self.addPhoto))
            videoButton.cornerRadius = 32
            videoButton.backgroundColor = Color.orange
            videoButton.highlightedColor = Color.orangeDark
            
            let liveButton = Button(icon: "D", size: 32)
            liveButton.clipsToBounds = true
            liveButton.addTarget(self, touchUpInside: #selector(self.startP2PCall))
            liveButton.cornerRadius = 32
            liveButton.backgroundColor = Color.orange
            liveButton.highlightedColor = Color.orangeDark
            
            contentView.add(photoButton) { (make) in
                make.top.equalTo(messageLabel.snp_bottom).offset(32)
                make.centerX.equalTo(contentView.snp_trailing).multipliedBy(1.0/6.0).offset(16)
                make.size.equalTo(64)
            }
            contentView.add(videoButton) { (make) in
                make.top.equalTo(messageLabel.snp_bottom).offset(32)
                make.centerX.equalTo(contentView)
                make.size.equalTo(64)
            }
            contentView.add(liveButton) { (make) in
                make.top.equalTo(messageLabel.snp_bottom).offset(32)
                make.centerX.equalTo(contentView.snp_trailing).multipliedBy(5.0/6.0).offset(-16)
                make.size.equalTo(64)
            }
            
        } else {
            backgroundImageView.contentMode = .ScaleAspectFill
            view.add(backgroundImageView) { (make) in
                make.edges.equalTo(view)
            }
            
            let topView = UIView()
            topView.backgroundColor = Color.grayDarker
            view.add(topView) { (make) in
                make.leading.top.trailing.equalTo(view)
            }
            
            topView.add(titleLabel) { (make) in
                make.top.equalTo(topView).inset(32)
                make.leading.trailing.bottom.equalTo(topView).inset(12)
            }
            
            let actionView = UIView()
            actionView.clipsToBounds = true
            actionView.cornerRadius = 6
            actionView.setBorder(color: Color.orange, width: 1)
            view.add(actionView) { (make) in
                make.bottom.equalTo(view).offset(-44)
                make.centerX.equalTo(view)
                make.height.equalTo(160)
                make.width.equalTo(296)
            }
            
            let actionTopView = UIView()
            actionTopView.backgroundColor = Color.orange
            actionView.add(actionTopView) { (make) in
                make.leading.top.trailing.equalTo(actionView)
            }
            
            let messageLabel = Label(preset: .Large, weight: .Semibold, textColor: UIColor.whiteColor())
            messageLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Vertical)
            let message = String(format: "f_send_photo_video_to_wrap_now".ls, name)
            messageLabel.numberOfLines = 0
            let messageText = NSMutableAttributedString(string: message, attributes: [NSFontAttributeName: Font.Large + .Semibold, NSForegroundColorAttributeName: UIColor.whiteColor()])
            messageText.addAttributes([NSFontAttributeName: UIFont.lightFontLarge()], range: (message as NSString).rangeOfString(name))
            messageLabel.attributedText = messageText
            actionTopView.add(messageLabel) { (make) in
                make.edges.equalTo(actionTopView).inset(12)
            }
            
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
            actionView.add(blurView) {
                $0.leading.bottom.trailing.equalTo(actionView)
                $0.top.equalTo(actionTopView.snp_bottom)
            }
            
            let photoButton = Button(icon: "u", size: 32)
            photoButton.clipsToBounds = true
            photoButton.addTarget(self, touchUpInside: #selector(self.addPhoto))
            photoButton.setTitleColor(Color.grayLight, forState: .Highlighted)
            photoButton.cornerRadius = 30
            photoButton.setBorder(color: UIColor.whiteColor())
            
            let videoButton = Button(icon: "+", size: 36)
            videoButton.clipsToBounds = true
            videoButton.addTarget(self, touchUpInside: #selector(self.addPhoto))
            videoButton.setTitleColor(Color.grayLight, forState: .Highlighted)
            videoButton.cornerRadius = 30
            videoButton.setBorder(color: UIColor.whiteColor())
            
            let liveButton = Button(preset: .Normal, weight: .Bold, textColor: .whiteColor())
            liveButton.clipsToBounds = true
            liveButton.addTarget(self, touchUpInside: #selector(self.startBroadcast))
            liveButton.setTitle("LIVE", forState: .Normal)
            liveButton.setTitleColor(Color.grayLight, forState: .Highlighted)
            liveButton.cornerRadius = 30
            liveButton.setBorder(color: UIColor.whiteColor())
            
            blurView.add(photoButton) { (make) in
                make.centerY.equalTo(blurView)
                make.centerX.equalTo(blurView).multipliedBy(0.4)
                make.size.equalTo(60)
            }
            blurView.add(videoButton) { (make) in
                make.centerY.equalTo(blurView)
                make.centerX.equalTo(blurView)
                make.size.equalTo(60)
            }
            blurView.add(liveButton) { (make) in
                make.centerY.equalTo(blurView)
                make.centerX.equalTo(blurView).multipliedBy(1.6)
                make.size.equalTo(60)
            }
        }
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        avatar.user = wrap?.contributors.filter({ !$0.current }).first
    }
    
    func addPhoto() {
        let nc = UINavigationController.main
        let controller = wrap!.createViewController() as! WrapViewController
        nc.viewControllers = nc.viewControllers.prefix(1) + [controller]
        controller.addPhoto()
    }
    
    func startBroadcast() {
        let nc = UINavigationController.main
        let controller = wrap!.createViewController() as! WrapViewController
        let liveController = LiveBroadcasterViewController()
        liveController.wrap = wrap
        nc.viewControllers = nc.viewControllers.prefix(1) + [controller, liveController]
    }
    
    func startP2PCall() {
        let nc = UINavigationController.main
        let controller = wrap!.createViewController() as! WrapViewController
        nc.viewControllers = nc.viewControllers.prefix(1) + [controller]
    }
}