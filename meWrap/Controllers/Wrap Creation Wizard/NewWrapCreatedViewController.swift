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
    
    private let avatarView = UIView()
    
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
        
        let contentView = UIView()
        view.add(contentView) { (make) in
            make.leading.trailing.equalTo(view)
            make.centerY.equalTo(view).offset(10)
            make.height.equalTo(view).offset(-148)
        }
        
        var size: CGSize = UIScreen.mainScreen().bounds.size.width ^ (UIScreen.mainScreen().bounds.height - 148)
        contentView.layer.mask = CAShapeLayer.mask(block: { (path) in
            path.move(0 ^ 0)
            path.addCurveToPoint(size.width ^ 0, controlPoint1: (size.width * 0.25) ^ 12, controlPoint2: (size.width * 0.75) ^ 12)
            path.line(size.width ^ size.height)
            path.addCurveToPoint(0 ^ size.height, controlPoint1: (size.width * 0.75) ^ (size.height - 12), controlPoint2: (size.width * 0.25) ^ (size.height - 12))
            path.line(0 ^ 0)
        })
        
        let background = UIImageView(image: UIImage(named: p2p ? "p2p_background" : "group_background"))
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
        actionsView.layer.mask = CAShapeLayer.mask(block: { (path) in
            path.move(0 ^ 10)
            path.addCurveToPoint(size.width ^ 10, controlPoint1: (size.width * 0.25) ^ -2, controlPoint2: (size.width * 0.75) ^ -2)
            path.line(size.width ^ size.height).line(0 ^ size.height).line(0 ^ 10)
        })
        
        contentView.add(avatarView, { (make) in
            make.centerX.equalTo(contentView)
            make.top.equalTo(actionsView).offset(-16)
        })
        
        updateAvatarView()
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
            make.top.equalTo(avatarView.snp_bottom).offset(20)
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
        
        var liveButton: Button!
        if p2p {
            liveButton = Button(icon: "D", size: 32)
            liveButton.addTarget(self, touchUpInside: #selector(self.startP2PCall))
        } else {
            liveButton = Button(preset: .Normal, weight: .Bold, textColor: .whiteColor())
            liveButton.addTarget(self, touchUpInside: #selector(self.startBroadcast))
            liveButton.setTitle("LIVE", forState: .Normal)
        }
        liveButton.clipsToBounds = true
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
    }
    
    private func updateAvatarView() {
        guard let wrap = wrap else { return }
        avatarView.subviews.all({ $0.removeFromSuperview() })
        
        var users: [User?] = []
        if !wrap.invitees.isEmpty {
            users = wrap.invitees.map({ $0.user })
        } else {
            users = wrap.contributors.map({ $0 })
        }
        
        let limit = Constants.screenWidth == 320 ? 4 : 5
        let size: CGFloat = p2p ? 62 : 58
        var previousAvatar: UserAvatarView?
        for (index, user) in users.enumerate() {
            
            if index == limit - 1 && users.count > limit {
                let countLabel = Label(preset: .Large, weight: .Semibold, textColor: .whiteColor())
                countLabel.textAlignment = .Center
                countLabel.text = "+\(users.count - index)"
                countLabel.backgroundColor = Color.orange
                countLabel.clipsToBounds = true
                countLabel.cornerRadius = size / 2
                countLabel.setBorder()
                if let previousAvatar = previousAvatar {
                    avatarView.add(countLabel, { (make) in
                        make.top.bottom.trailing.equalTo(avatarView)
                        make.leading.equalTo(previousAvatar.snp_trailing).offset(10)
                        make.size.equalTo(size)
                    })
                }
                break
            }
            
            let avatar = UserAvatarView(cornerRadius: size / 2, backgroundColor: UIColor.clearColor(), placeholderSize: 24)
            avatar.setBorder()
            avatarView.add(avatar, { (make) in
                
                if users.count == 1 {
                    make.edges.equalTo(avatarView)
                } else {
                    make.top.bottom.equalTo(avatarView)
                    if let previousAvatar = previousAvatar {
                        make.leading.equalTo(previousAvatar.snp_trailing).offset(10)
                        if index == users.count - 1 {
                            make.trailing.equalTo(avatarView)
                        }
                    } else {
                        make.leading.equalTo(avatarView)
                    }
                }
                make.size.equalTo(size)
            })
            previousAvatar = avatar
            
            avatar.user = user
        }
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        updateAvatarView()
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