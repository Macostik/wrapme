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
            case .Live: return LiveActivityAnimationView()
            case .Photo: return PhotoActivityAnimationView()
            case .Video: return VideoActivityAnimationView()
            default: return nil
            }
        }
        
        init() {
            super.init(frame: CGRect.zero)
            layout()
        }
        
        func layout() { }
        
        func layoutInFriendView(friendView: FriendView) {
            backgroundColor = Color.dangerRed
            clipsToBounds = true
            cornerRadius = 10
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
        
        override func layout() {
            let pencil = Label(icon: "<", size: 10, textColor: UIColor.whiteColor())
            let stroke = CAShapeLayer()
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
            pencil.addAnimation(CAAnimationGroup()) {
                $0.removedOnCompletion = false
                $0.duration = 2
                $0.repeatCount = FLT_MAX
                $0.animations = [specifyAnimation(CABasicAnimation(keyPath: "position.y"), {
                    $0.fromValue = 10
                    $0.toValue = 9
                    $0.duration = 0.15
                    $0.repeatCount = 10
                    $0.autoreverses = true
                }), specifyAnimation(CABasicAnimation(keyPath: "position.x"), {
                    $0.fromValue = 7
                    $0.toValue = 14
                    $0.duration = 1.6
                    $0.fillMode = kCAFillModeForwards
                }), specifyAnimation(CAKeyframeAnimation(keyPath: "position"), {
                    $0.beginTime = 1.6
                    $0.path = UIBezierPath().move(14, 10).quadCurve(7, 10, controlX: 10.5, controlY: 4).CGPath
                    $0.duration = 0.4
                })]
            }
            stroke.addAnimation(CAAnimationGroup()) {
                $0.removedOnCompletion = false
                $0.duration = 2
                $0.repeatCount = FLT_MAX
                $0.animations = [specifyAnimation(CABasicAnimation(keyPath: "strokeEnd"), {
                    $0.fromValue = 0
                    $0.toValue = 1
                    $0.duration = 1.6
                    $0.fillMode = kCAFillModeForwards
                }), specifyAnimation(CABasicAnimation(keyPath: "strokeEnd"), {
                    $0.beginTime = 1.6
                    $0.fromValue = 1
                    $0.toValue = 0
                    $0.duration = 0.2
                    $0.fillMode = kCAFillModeForwards
                })]
            }
        }
    }
    
    class PhotoActivityAnimationView: ActivityAnimationView {
        
        override func layout() {
            let iconView = Label(icon: "u", size: 12, textColor: UIColor.whiteColor())
            addSubview(iconView)
            iconView.snp_makeConstraints { $0.center.equalTo(self) }
            iconView.addAnimation(CAAnimationGroup()) {
                $0.removedOnCompletion = false
                $0.duration = 0.9
                $0.repeatCount = FLT_MAX
                $0.animations = [specifyAnimation(CABasicAnimation(keyPath: "transform"), {
                    $0.toValue = NSValue(CATransform3D: CATransform3DScale(CATransform3DMakeRotation(CGFloat(M_PI_4), 0, 0, 1), 1.2, 1.2, 1))
                    $0.duration = 0.3
                    $0.autoreverses = true
                }), specifyAnimation(CABasicAnimation(keyPath: "opacity"), {
                    $0.toValue = 0.75
                    $0.duration = 0.3
                    $0.autoreverses = true
                })]
            }
        }
    }
    
    class VideoActivityAnimationView: ActivityAnimationView {
        
        override func layout() {
            specifyObject(CAShapeLayer()) {
                $0.frame = CGRectMake(4, 6, 8, 8)
                $0.path = UIBezierPath(roundedRect: CGRectMake(0, 0, 8, 8), cornerRadius: 1).CGPath
                $0.fillColor = UIColor.whiteColor().CGColor
                layer.addSublayer($0)
            }
            specifyObject(CAShapeLayer()) {
                $0.frame = CGRectMake(13, 7, 3, 6)
                $0.path = UIBezierPath().move(3, 0).line(3, 6).line(0, 5).line(0, 1).line(3, 0).CGPath
                $0.fillColor = UIColor.whiteColor().CGColor
                layer.addSublayer($0)
                $0.addAnimation(CABasicAnimation(keyPath: "opacity")) {
                    $0.toValue = 0
                    $0.duration = 0.6
                    $0.autoreverses = true
                    $0.removedOnCompletion = false
                    $0.repeatCount = FLT_MAX
                }
            }
        }
    }
    
    class LiveActivityAnimationView: ActivityAnimationView {
        
        override func layout() {
            let liveBadge = UILabel()
            liveBadge.textColor = UIColor.whiteColor()
            liveBadge.font = UIFont.systemFontOfSize(8, weight: UIFontWeightLight)
            liveBadge.text = "LIVE"
            addSubview(liveBadge)
            liveBadge.snp_makeConstraints(closure: { $0.edges.equalTo(self).inset(2) })
            liveBadge.addAnimation(CABasicAnimation(keyPath: "opacity")) {
                $0.toValue = 0
                $0.duration = 0.6
                $0.autoreverses = true
                $0.removedOnCompletion = false
                $0.repeatCount = FLT_MAX
            }
        }
        
        override func layoutInFriendView(friendView: FriendView) {
            backgroundColor = Color.dangerRed
            clipsToBounds = true
            cornerRadius = 3
            snp_makeConstraints { $0.bottom.trailing.equalTo(friendView.avatarView) }
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
    
    private func activityAnimationView(friend: User) -> ActivityAnimationView? {
        guard let wrap = wrap, let activity = friend.activityForWrap(wrap) else { return nil }
        return ActivityAnimationView.animationView(activity.type)
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
            
            activityAnimationView = activityAnimationView(friend)
            statusView.hidden = (activityAnimationView != nil) || !(friend.current || friend.isActive)
        }
    }
}