//
//  FriendView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 3/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

final class FriendView: StreamReusableView {
    
    private let avatarView = StatusUserAvatarView(cornerRadius: 16)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        avatarView.backgroundColor = UIColor.whiteColor()
        addSubview(avatarView)
        avatarView.snp_makeConstraints(closure: {
            $0.width.height.equalTo(32)
            $0.centerY.equalTo(self)
            $0.trailing.equalTo(self)
        })
    }
    
    weak var wrap: Wrap?
    
    override func setup(entry: AnyObject?) {
        if let friend = entry as? User {
            avatarView.wrap = wrap
            avatarView.user = friend
        }
    }
}

class UserAvatarView: ImageView {
    
    convenience init(cornerRadius: CGFloat, backgroundColor: UIColor = UIColor.clearColor()) {
        self.init(backgroundColor: backgroundColor)
        self.cornerRadius = cornerRadius
        defaultIconSize = 16
        defaultIconText = "&"
        defaultIconColor = UIColor.whiteColor()
        defaultBackgroundColor = Color.grayLighter
    }
    
    weak var user: User? {
        willSet {
            if let user = newValue {
                update(user)
            } else {
                clear()
            }
        }
    }
    
    internal func update(user: User) {
        let url = user.avatar?.small
        if !user.isInvited && url?.isEmpty ?? true {
            defaultBackgroundColor = Color.orange
        } else {
            defaultBackgroundColor = Color.grayLighter
        }
        self.url = url
    }
    
    internal func clear() {
        url = nil
    }
}

final class StatusUserAvatarView: UserAvatarView, EntryNotifying {
    
    class ActivityAnimationView: UIView {
        
        class func animationView(type: UserActivityType) -> ActivityAnimationView? {
            switch type {
            case .Typing: return TypingActivityAnimationView()
            case .Live: return LiveActivityAnimationView()
            case .Photo: return PhotoActivityAnimationView()
            case .Video: return VideoActivityAnimationView()
            case .Drawing: return DrawingActivityAnimationView()
            default: return nil
            }
        }
        
        init() {
            super.init(frame: CGRect.zero)
            layout()
        }
        
        func layout() { }
        
        func layoutInView(avatarView: StatusUserAvatarView) {
            backgroundColor = Color.dangerRed
            clipsToBounds = true
            cornerRadius = 10
            snp_makeConstraints {
                $0.size.equalTo(20)
                $0.center.equalTo(avatarView.statusView)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    final class TypingActivityAnimationView: ActivityAnimationView {
        
        override func layout() {
            let pencil = Label(icon: "<", size: 10, textColor: UIColor.whiteColor())
            let stroke = CAShapeLayer()
            addSubview(pencil)
            stroke.fillColor = UIColor.clearColor().CGColor
            stroke.strokeColor = UIColor.whiteColor().CGColor
            stroke.strokeStart = 0
            stroke.strokeEnd = 0
            stroke.frame = CGRectMake(3, 13, 7, 2)
            stroke.path = UIBezierPath().move(0 ^ 1).line(7 ^ 1).CGPath
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
                $0.animations = [specify(CABasicAnimation(keyPath: "position.y"), {
                    $0.fromValue = 10
                    $0.toValue = 9
                    $0.duration = 0.15
                    $0.repeatCount = 10
                    $0.autoreverses = true
                }), specify(CABasicAnimation(keyPath: "position.x"), {
                    $0.fromValue = 7
                    $0.toValue = 14
                    $0.duration = 1.6
                    $0.fillMode = kCAFillModeForwards
                }), specify(CAKeyframeAnimation(keyPath: "position"), {
                    $0.beginTime = 1.6
                    $0.path = UIBezierPath().move(14 ^ 10).quadCurve(7 ^ 10, controlPoint: 10.5 ^ 4).CGPath
                    $0.duration = 0.4
                })]
            }
            stroke.addAnimation(CAAnimationGroup()) {
                $0.removedOnCompletion = false
                $0.duration = 2
                $0.repeatCount = FLT_MAX
                $0.animations = [specify(CABasicAnimation(keyPath: "strokeEnd"), {
                    $0.fromValue = 0
                    $0.toValue = 1
                    $0.duration = 1.6
                    $0.fillMode = kCAFillModeForwards
                }), specify(CABasicAnimation(keyPath: "strokeEnd"), {
                    $0.beginTime = 1.6
                    $0.fromValue = 1
                    $0.toValue = 0
                    $0.duration = 0.2
                    $0.fillMode = kCAFillModeForwards
                })]
            }
        }
    }
    
    final class PhotoActivityAnimationView: ActivityAnimationView {
        
        override func layout() {
            let iconView = Label(icon: "u", size: 12, textColor: UIColor.whiteColor())
            addSubview(iconView)
            iconView.snp_makeConstraints { $0.center.equalTo(self) }
            iconView.addAnimation(CAAnimationGroup()) {
                $0.removedOnCompletion = false
                $0.duration = 0.9
                $0.repeatCount = FLT_MAX
                $0.animations = [specify(CABasicAnimation(keyPath: "transform"), {
                    $0.toValue = NSValue(CATransform3D: CATransform3DScale(CATransform3DMakeRotation(CGFloat(M_PI_4), 0, 0, 1), 1.2, 1.2, 1))
                    $0.duration = 0.3
                    $0.autoreverses = true
                }), specify(CABasicAnimation(keyPath: "opacity"), {
                    $0.toValue = 0.75
                    $0.duration = 0.3
                    $0.autoreverses = true
                })]
            }
        }
    }
    
    final class VideoActivityAnimationView: ActivityAnimationView {
        
        override func layout() {
            specify(CAShapeLayer()) {
                $0.frame = CGRectMake(4, 6, 8, 8)
                $0.path = UIBezierPath(roundedRect: CGRectMake(0, 0, 8, 8), cornerRadius: 1).CGPath
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
            specify(CAShapeLayer()) {
                $0.frame = CGRectMake(13, 7, 3, 6)
                $0.path = UIBezierPath().move(3 ^ 0).line(3 ^ 6).line(0 ^ 5).line(0 ^ 1).line(3 ^ 0).CGPath
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
    
    final class LiveActivityAnimationView: ActivityAnimationView {
        
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
        
        override func layoutInView(avatarView: StatusUserAvatarView) {
            backgroundColor = Color.dangerRed
            clipsToBounds = true
            cornerRadius = 3
            snp_makeConstraints { $0.bottom.trailing.equalTo(avatarView) }
        }
    }
    
    final class DrawingActivityAnimationView: ActivityAnimationView {
        
        override func layout() {
            let imageView = UIImageView()
            imageView.contentMode = .ScaleAspectFill
            addSubview(imageView)
            imageView.snp_makeConstraints(closure: { $0.edges.equalTo(self) })
            var images = [UIImage]()
            for i in 0...49 {
                if let image = UIImage(named: "ic_anim_drawing_\(i)") {
                    images.append(image)
                }
            }
            imageView.animationImages = images
            imageView.startAnimating()
        }
    }
    
    private lazy var statusView: UIView = {
        let statusView = UIView()
        statusView.clipsToBounds = true
        statusView.cornerRadius = 6
        statusView.backgroundColor = Color.greenOnline
        self.superview?.addSubview(statusView)
        statusView.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(12)
            make.centerY.equalTo(self.snp_bottom).multipliedBy(0.853)
            make.centerX.equalTo(self.snp_trailing).multipliedBy(0.853)
        }
        return statusView
    }()
    
    private var activityAnimationView: ActivityAnimationView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = activityAnimationView {
                superview?.addSubview(view)
                view.layoutInView(self)
            }
        }
    }
    
    weak var wrap: Wrap?
    
    private func activityAnimationView(user: User) -> ActivityAnimationView? {
        guard let wrap = wrap, let activity = user.activityForWrap(wrap) else { return nil }
        return ActivityAnimationView.animationView(activity.type)
    }
    
    override func clear() {
        activityAnimationView = nil
        statusView.hidden = true
        super.clear()
    }
    
    override func update(user: User) {
        super.update(user)
        activityAnimationView = activityAnimationView(user)
        statusView.hidden = (activityAnimationView != nil) || !(user.current || user.isActive)
    }
    
    func startReceivingStatusUpdates() {
        User.notifier().addReceiver(self)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry == user
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if let user = entry as? User where event == .UserStatus {
            update(user)
        }
    }
}