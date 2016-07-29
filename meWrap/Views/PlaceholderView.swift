//
//  PlaceholderView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class PlaceholderView: UIView {
    
    static func placeholderView(iconName: String, message: String, color: UIColor = Color.grayLighter) -> (() -> PlaceholderView) {
        return {
            let view = PlaceholderView()
            view.userInteractionEnabled = false
            view.addSubview(view.textLabel)
            view.addSubview(view.iconLabel)
            view.iconLabel.snp_makeConstraints { (make) -> Void in
                make.top.centerX.equalTo(view)
                make.bottom.equalTo(view.textLabel.snp_top).inset(-12)
            }
            view.textLabel.snp_makeConstraints { (make) -> Void in
                make.leading.trailing.bottom.equalTo(view)
            }
            view.textLabel.textColor = color
            view.iconLabel.textColor = color
            view.textLabel.text = message
            view.iconLabel.text = iconName
            return view
        }
    }
    
    let textLabel = specify(Label(preset: .Larger, textColor: Color.grayLighter)) {
        $0.numberOfLines = 0
        $0.textAlignment = .Center
    }
    let iconLabel = Label(icon: "", size: 96, textColor: Color.grayLighter)
    
    func layoutInStreamView(streamView: StreamView) {
        streamView.add(self, { (make) in
            make.centerX.equalTo(streamView)
            make.centerY.equalTo(streamView).offset(streamView.layout.offset/2 - streamView.contentInset.top/2)
            make.size.lessThanOrEqualTo(streamView).offset(-24)
        })
    }
}

extension PlaceholderView {
    
    static func chatPlaceholder() -> (() -> PlaceholderView) {
        return placeholderView("7", message: "")
    }
    
    static func commentsPlaceholder() -> (() -> PlaceholderView) {
        return placeholderView("q", message: "no_comments_yet".ls, color: Color.grayLightest.colorWithAlphaComponent(0.5))
    }
    
    static func inboxPlaceholder() -> (() -> PlaceholderView) {
        return placeholderView("J", message: "inbox_placeholder".ls)
    }
    
    static func mediaPlaceholder() -> (() -> PlaceholderView) {
        return placeholderView("C", message: "no_upload_yet".ls)
    }
    
    static func singleDayPlaceholder() -> (() -> PlaceholderView) {
        return placeholderView("C", message: "no_uploads_for_this_day".ls)
    }
    
    static func searchPlaceholder() -> (() -> PlaceholderView) {
        return placeholderView(":", message: "no_contacts_with_phone_number".ls)
    }
    
    static func sharePlaceholder() -> (() -> PlaceholderView) {
        return placeholderView("C", message: "no_wraps_found".ls)
    }
    
    static func homePlaceholder(actionBlock: (UIButton -> Void)) -> (() -> PlaceholderView) {
        return {
            let view = HomePlaceholderView()
            view.backgroundColor = UIColor(hex: 0x6DAFF8).colorByAddingValue(0.06)
            let string = "easy_create_wrap".ls
            let text = NSMutableAttributedString(string: string, attributes: [NSForegroundColorAttributeName: UIColor(white: 0, alpha: 0.87), NSFontAttributeName: Font.Large + .Light])
            text.addAttributes([NSForegroundColorAttributeName: UIColor(white: 0, alpha: 0.87), NSFontAttributeName: Font.Large + .Semibold], range: (string as NSString).rangeOfString("meWrap"))
            view.textLabel.attributedText = text
            let actionButton = Button(type: .Custom)
            actionButton.setTitle("let's_get_started".ls, forState: .Normal)
            actionButton.backgroundColor = Color.orange
            actionButton.normalColor = Color.orange
            actionButton.highlightedColor = Color.orangeDark
            actionButton.titleLabel?.font = Font.Normal + .Regular
            actionButton.clipsToBounds = true
            actionButton.cornerRadius = 20
            actionButton.insets.width = 60
            actionBlock(actionButton)
            view.add(actionButton) { (make) -> Void in
                make.height.equalTo(40)
                make.centerX.equalTo(view)
                make.bottom.equalTo(view).offset(-43)
            }
            view.add(view.textLabel, { (make) in
                make.centerX.equalTo(view)
                make.width.equalTo(250)
                make.bottom.equalTo(actionButton.snp_top).offset(-14)
            })
            view.userInteractionEnabled = true
            
            view.add(view.imageView, { (make) in
                make.leading.trailing.equalTo(view)
                make.bottom.equalTo(view.textLabel.snp_top).offset(-20)
                make.height.equalTo(view.imageView.snp_width).multipliedBy(0.563)
            })
            let whiteBackground = UIView()
            whiteBackground.backgroundColor = UIColor.whiteColor()
            view.insertSubview(whiteBackground, atIndex: 0)
            whiteBackground.snp_makeConstraints(closure: { (make) in
                make.leading.bottom.trailing.equalTo(view)
                make.top.equalTo(view.imageView.snp_bottom).offset(-20)
            })
            
            let topLabel = Label(preset: .Large, weight: .Regular, textColor: UIColor(white: 1, alpha: 0.54))
            topLabel.text = "no_wraps_yet".ls
            view.add(topLabel) { make in
                make.bottom.equalTo(view.imageView.snp_top).offset(-30)
                make.centerX.equalTo(view)
            }
            
            let topImageView = UIImageView(image: UIImage(named: "img_no_wraps_yet"))
            view.add(topImageView) { make in
                make.bottom.equalTo(topLabel.snp_top)
                make.centerX.equalTo(view)
            }
            
            return view
        }
    }
}

final class HomePlaceholderView: PlaceholderView {
    
    let imageView = UIImageView(image: UIImage(named: "create_wrap_step_first"))
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size = imageView.size
        let mask = CAShapeLayer()
        let path = UIBezierPath()
        path.move(0 ^ size.height).line(0 ^ 0).line(size.width ^ 0).line(size.width ^ size.height)
        path.addCurveToPoint(0 ^ size.height, controlPoint1: (size.width * 0.75) ^ (size.height - 14), controlPoint2: (size.width * 0.25) ^ (size.height - 14))
        mask.path = path.CGPath
        imageView.layer.mask = mask
    }
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath()
        path.move(0 ^ 22).line(0 ^ 0).line(rect.size.width ^ 0).line(rect.size.width ^ 22)
        path.addCurveToPoint(0 ^ 22, controlPoint1: (rect.size.width * 0.75) ^ -6, controlPoint2: (rect.size.width * 0.25) ^ -6)
        Color.orange.setFill()
        path.fill()
    }
    
    override func layoutInStreamView(streamView: StreamView) {
        guard let superview = streamView.superview else { return }
        superview.add(self, { (make) in
            make.top.equalTo(superview).offset(64)
            make.leading.bottom.trailing.equalTo(superview)
        })
    }
}