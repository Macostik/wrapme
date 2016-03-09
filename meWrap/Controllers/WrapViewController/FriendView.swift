//
//  FriendView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 3/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

final class FriendView: StreamReusableView {
    
    class ActivityAnimationView: UIView {
        
        init() {
            super.init(frame: CGRect.zero)
            layout()
        }
        
        func layout() {
            cornerRadius = 10
            clipsToBounds = true
            backgroundColor = Color.dangerRed
        }
        
        func layoutInFriendView(friendView: FriendView) {
            snp_makeConstraints { (make) -> Void in
                make.size.equalTo(20)
                make.center.equalTo(friendView.statusView)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class PhotoActivityAnimationView: ActivityAnimationView {
        
        private let iconView = Label(icon: "u", size: 12, textColor: UIColor.whiteColor())
        
        override func layout() {
            super.layout()
            addSubview(iconView)
            iconView.snp_makeConstraints { $0.center.equalTo(self) }
            let animationGroup = CAAnimationGroup()
            
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.toValue = NSValue(CATransform3D: CATransform3DScale(CATransform3DMakeRotation(CGFloat(M_PI_4), 0, 0, 1), 1.2, 1.2, 1))
            transformAnimation.duration = 0.3
            transformAnimation.autoreverses = true
            
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.toValue = 0.75
            opacityAnimation.duration = 0.3
            opacityAnimation.autoreverses = true
            
            animationGroup.removedOnCompletion = false
            animationGroup.duration = 0.9
            animationGroup.repeatCount = FLT_MAX
            animationGroup.animations = [transformAnimation, opacityAnimation]
            iconView.addAnimation(animationGroup)
        }
    }
    
    class VideoActivityAnimationView: ActivityAnimationView {
        
        private let cameraLayer1 = CAShapeLayer()
        
        private let cameraLayer2 = CAShapeLayer()
        
        override func layout() {
            super.layout()
            cameraLayer1.frame = CGRectMake(4, 6, 8, 8)
            let path1 = UIBezierPath(roundedRect: CGRectMake(0, 0, 8, 8), cornerRadius: 1)
            cameraLayer1.path = path1.CGPath
            cameraLayer1.fillColor = UIColor.whiteColor().CGColor
            cameraLayer2.frame = CGRectMake(13, 7, 3, 6)
            let path2 = UIBezierPath().move(3, 0).line(3, 6).line(0, 5).line(0, 1).line(3, 0)
            cameraLayer2.path = path2.CGPath
            cameraLayer2.fillColor = UIColor.whiteColor().CGColor
            layer.addSublayer(cameraLayer1)
            layer.addSublayer(cameraLayer2)
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.toValue = 0
            opacityAnimation.duration = 0.6
            opacityAnimation.autoreverses = true
            opacityAnimation.removedOnCompletion = false
            opacityAnimation.repeatCount = FLT_MAX
            cameraLayer2.addAnimation(opacityAnimation, forKey: nil)
        }
    }
    
    private let avatarView = ImageView(backgroundColor: UIColor.whiteColor())
    
    private let statusView = UIView()
    
    private var activityAnimationView: ActivityAnimationView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = activityAnimationView {
                addSubview(view)
                view.layoutInFriendView(self)
            }
        }
    }
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        avatarView.cornerRadius = 16
        avatarView.defaultBackgroundColor = Color.grayLighter
        avatarView.defaultIconColor = UIColor.whiteColor()
        avatarView.defaultIconText = "&"
        statusView.clipsToBounds = true
        statusView.cornerRadius = 6
        statusView.backgroundColor = Color.greenOnline
        addSubview(avatarView)
        addSubview(statusView)
        avatarView.snp_makeConstraints(closure: {
            $0.width.height.equalTo(32)
            $0.centerY.equalTo(self)
            $0.trailing.equalTo(self)
        })
        statusView.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(12)
            make.trailing.bottom.equalTo(avatarView)
        }
    }
    
    override func setup(entry: AnyObject?) {
        if let friend = entry as? User {
            let url = friend.avatar?.small
            if !friend.isInvited && url?.isEmpty ?? true {
                avatarView.defaultBackgroundColor = Color.orange
            } else {
                avatarView.defaultBackgroundColor = Color.grayLighter
            }
            avatarView.url = url
            
            if friend.activity.inProgress {
                if friend.activity.type == .Photo {
                    activityAnimationView = PhotoActivityAnimationView()
                    statusView.hidden = true
                } else if friend.activity.type == .Video {
                    activityAnimationView = VideoActivityAnimationView()
                    statusView.hidden = true
                } else {
                    activityAnimationView = nil
                    statusView.hidden = !(friend.current || friend.isActive)
                }
            } else {
                activityAnimationView = nil
                statusView.hidden = !(friend.current || friend.isActive)
            }
        }
    }
}