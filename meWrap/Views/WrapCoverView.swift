//
//  WrapCoverImageView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class WrapCoverView: OverlayImageView {
    
    static var FollowerImage = "%"
    static var OwnerImage = "'"

    private weak var _statusView: UILabel?
    private weak var statusView: UILabel? {
        if _statusView == nil {
            let statusView = UILabel()
            statusView.textColor = WLColors.dangerRed
            statusView.backgroundColor = UIColor.whiteColor()
            statusView.clipsToBounds = true
            statusView.textAlignment = .Center
            statusView.borderColor = WLColors.dangerRed
            statusView.borderWidth = 2
            statusView.text = "%"
            _statusView = statusView
            updateStatusView(statusView)
        }
        return _statusView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let statusView = _statusView {
            updateStatusView(statusView)
        }
    }
    
    private func updateStatusView(statusView: UILabel) {
        let angle = CGFloat(M_PI + M_PI_4)
        let radius: CGFloat = height / 2
        let point = CGPoint(x: center.x + radius*cos(angle), y: center.y + radius*sin(angle))
        let size: CGFloat = max(16, height / 3)
        statusView.frame = CGRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size)
        statusView.font = UIFont(name: "icons", size: size/2)
        statusView.circled = true
        if let superview = superview where statusView.superview != superview {
            superview.insertSubview(statusView, aboveSubview: self)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let statusView = _statusView {
            updateStatusView(statusView)
        }
    }
    
    override func overlayIdentifier() -> String {
        if isFollowed {
            return "WrapFollowed"
        } else {
            return super.overlayIdentifier()
        }
    }
    
    override func drawOverlayImageInRect(rect: CGRect) {
        super.drawOverlayImageInRect(rect)
        if isFollowed {
            WLColors.dangerRed.setStroke()
            let ovalPath = UIBezierPath(ovalInRect: rect.insetBy(dx: 1, dy: 1))
            ovalPath.lineWidth = 2
            ovalPath.stroke()
        }
    }
    
    var isFollowed = false {
        didSet {
            statusView?.hidden = !isFollowed
            updateOverlay()
        }
    }
    
    var isOwner = false {
        didSet {
            statusView?.text = isOwner ? WrapCoverView.OwnerImage : WrapCoverView.FollowerImage
        }
    }

}
