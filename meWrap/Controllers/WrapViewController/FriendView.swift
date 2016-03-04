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
            clipsToBounds = true
            backgroundColor = Color.dangerRed
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
            iconView.snp_makeConstraints { (make) -> Void in
                make.center.equalTo(self)
            }
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
    
    private let avatarView = ImageView(backgroundColor: UIColor.whiteColor())
    
    private let statusView = UIView()
    
    private var activityAnimationView: ActivityAnimationView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = activityAnimationView {
                view.cornerRadius = 10
                addSubview(view)
                view.snp_makeConstraints { (make) -> Void in
                    make.size.equalTo(20)
                    make.center.equalTo(statusView)
                }
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
                } else {
                    activityAnimationView = nil
                    statusView.hidden = !friend.isActive
                }
            } else {
                activityAnimationView = nil
                statusView.hidden = !friend.isActive
            }
        }
    }
}