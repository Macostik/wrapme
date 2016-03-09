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
        
        class func animationView(type: UserActivityType) -> ActivityAnimationView? {
            switch type {
            case .Typing: return TypingActivityAnimationView()
            case .Photo: return PhotoActivityAnimationView()
            case .Video: return VideoActivityAnimationView()
            default: return nil
            }
        }
        
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
    
    class TypingActivityAnimationView: ActivityAnimationView {
        
        private let pencil = Label(icon: "<", size: 10, textColor: UIColor.whiteColor())
        
        private let stroke = CAShapeLayer()
        
        override func layout() {
            super.layout()
            addSubview(pencil)
            stroke.fillColor = UIColor.clearColor().CGColor
            stroke.strokeColor = UIColor.whiteColor().CGColor
            stroke.strokeStart = 0
            stroke.strokeEnd = 0
            stroke.frame = CGRectMake(3, 13, 7, 2)
            stroke.path = UIBezierPath().move(0, 1).line(7, 1).CGPath
            stroke.lineDashPattern = [3, 1, 3]
            stroke.lineWidth = 1
            layer.addSublayer(stroke)
            
            pencil.snp_makeConstraints {
                $0.centerX.equalTo(self).inset(-3)
                $0.centerY.equalTo(self)
            }
            
            let pencilAnimationGroup = CAAnimationGroup()
            
            let pencilAnimation1 = CABasicAnimation(keyPath: "position.y")
            pencilAnimation1.fromValue = 10
            pencilAnimation1.toValue = 9
            pencilAnimation1.duration = 0.15
            pencilAnimation1.repeatCount = 10
            pencilAnimation1.autoreverses = true
            
            let pencilAnimation2 = CABasicAnimation(keyPath: "position.x")
            pencilAnimation2.fromValue = 7
            pencilAnimation2.toValue = 14
            pencilAnimation2.duration = 1.6
            pencilAnimation2.fillMode = kCAFillModeForwards
            
            let pencilAnimation3 = CAKeyframeAnimation(keyPath: "position")
            pencilAnimation3.beginTime = 1.6
            pencilAnimation3.path = UIBezierPath().move(14, 10).quadCurve(7, 10, controlX: 10.5, controlY: 4).CGPath
            pencilAnimation3.duration = 0.4
            
            pencilAnimationGroup.removedOnCompletion = false
            pencilAnimationGroup.duration = 2
            pencilAnimationGroup.repeatCount = FLT_MAX
            pencilAnimationGroup.animations = [pencilAnimation1, pencilAnimation2, pencilAnimation3]
            pencil.addAnimation(pencilAnimationGroup)
            
            let strokeAnimationGroup = CAAnimationGroup()
            
            let strokeAnimation1 = CABasicAnimation(keyPath: "strokeEnd")
            strokeAnimation1.fromValue = 0
            strokeAnimation1.toValue = 1
            strokeAnimation1.duration = 1.6
            strokeAnimation1.fillMode = kCAFillModeForwards
            
            let strokeAnimation2 = CABasicAnimation(keyPath: "strokeEnd")
            strokeAnimation2.beginTime = 1.6
            strokeAnimation2.fromValue = 1
            strokeAnimation2.toValue = 0
            strokeAnimation2.duration = 0.2
            strokeAnimation2.fillMode = kCAFillModeForwards
            
            strokeAnimationGroup.removedOnCompletion = false
            strokeAnimationGroup.duration = 2
            strokeAnimationGroup.repeatCount = FLT_MAX
            strokeAnimationGroup.animations = [strokeAnimation1, strokeAnimation2]
            stroke.addAnimation(strokeAnimationGroup, forKey: nil)
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
        avatarView.defaultIconSize = 16
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
    
    weak var wrap: Wrap?
    
    override func setup(entry: AnyObject?) {
        if let friend = entry as? User {
            let url = friend.avatar?.small
            if !friend.isInvited && url?.isEmpty ?? true {
                avatarView.defaultBackgroundColor = Color.orange
            } else {
                avatarView.defaultBackgroundColor = Color.grayLighter
            }
            avatarView.url = url
            
            if friend.activity.wrap == wrap && friend.activity.inProgress {
                if let animationView = ActivityAnimationView.animationView(friend.activity.type) {
                    activityAnimationView = animationView
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