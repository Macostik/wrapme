//
//  NewWrapCreatedViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 7/19/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class NewWrapCreatedViewController: BaseViewController {
        
    internal let backgroundImageView = UIImageView()
    
    var wrap: Wrap?
    
    var p2p = false
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = Color.grayDarker
        backgroundImageView.contentMode = .ScaleAspectFill
        view.add(backgroundImageView) { (make) in
            make.edges.equalTo(view)
        }
        
        let topView = UIView()
        topView.backgroundColor = Color.grayDarker
        view.add(topView) { (make) in
            make.leading.top.trailing.equalTo(view)
        }
        
        let titleLabel = Label(preset: .Large, weight: .Semibold, textColor: UIColor.whiteColor())
        titleLabel.numberOfLines = 0
        let name = "\(p2p ? "@" : "")\(wrap?.name ?? "")"
        let title = String(format: "f_wrap_created_congratulations".ls, name)
        let titleText = NSMutableAttributedString(string: title, attributes: [NSFontAttributeName: Font.Large + .Semibold, NSForegroundColorAttributeName: UIColor.whiteColor()])
        titleText.addAttributes([NSFontAttributeName: UIFont.lightFontLarge(), NSForegroundColorAttributeName: Color.orange], range: (title as NSString).rangeOfString(name))
        titleLabel.attributedText = titleText
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
        
        var liveButton: Button!
        if p2p {
            liveButton = Button(icon: "D", size: 32)
            liveButton.clipsToBounds = true
            liveButton.addTarget(self, touchUpInside: #selector(self.startP2PCall))
            liveButton.setTitleColor(Color.grayLight, forState: .Highlighted)
            liveButton.cornerRadius = 30
            liveButton.setBorder(color: UIColor.whiteColor())
        } else {
            liveButton = Button(preset: .Normal, weight: .Bold, textColor: .whiteColor())
            liveButton.clipsToBounds = true
            liveButton.addTarget(self, touchUpInside: #selector(self.startBroadcast))
            liveButton.setTitle("LIVE", forState: .Normal)
            liveButton.setTitleColor(Color.grayLight, forState: .Highlighted)
            liveButton.cornerRadius = 30
            liveButton.setBorder(color: UIColor.whiteColor())
        }
        
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