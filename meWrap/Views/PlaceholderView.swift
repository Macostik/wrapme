//
//  PlaceholderView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class PlaceholderView: StreamReusableView {
    
    class func metrics(iconName: String, message: String, color: UIColor = Color.grayLighter) -> StreamMetrics<PlaceholderView> {
        return StreamMetrics<PlaceholderView>(layoutBlock: { view in
            view.textLabel.textColor = color
            view.iconLabel.textColor = color
            view.textLabel.text = message
            view.iconLabel.text = iconName
        })
    }
    
    let containerView = UIView()
    
    let textLabel = specify(Label(preset: .Larger, textColor: Color.grayLighter)) {
        $0.numberOfLines = 0
        $0.textAlignment = .Center
    }
    let iconLabel = Label(icon: "", size: 96, textColor: Color.grayLighter)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        userInteractionEnabled = false
        addSubview(containerView)
        containerView.addSubview(textLabel)
        containerView.addSubview(iconLabel)
        containerView.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self)
            make.leading.trailing.greaterThanOrEqualTo(self).inset(12)
        }
        iconLabel.snp_makeConstraints { (make) -> Void in
            make.top.centerX.equalTo(containerView)
            make.bottom.equalTo(textLabel.snp_top).inset(-12)
        }
        textLabel.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.bottom.equalTo(containerView)
        }
    }
}

extension PlaceholderView {
    
    class func chatPlaceholderMetrics() -> StreamMetrics<PlaceholderView> {
        return metrics("7", message: "")
    }
    
    class func commentsPlaceholderMetrics() -> StreamMetrics<PlaceholderView> {
        return metrics("q", message: "no_comments_yet".ls, color: Color.grayLightest.colorWithAlphaComponent(0.5))
    }
    
    class func hottestPlaceholderMetrics() -> StreamMetrics<PlaceholderView> {
        return metrics("C", message: "coming_soon".ls)
    }
    
    class func inboxPlaceholderMetrics() -> StreamMetrics<PlaceholderView> {
        return metrics("J", message: "inbox_placeholder".ls)
    }
    
    class func mediaPlaceholderMetrics() -> StreamMetrics<PlaceholderView> {
        return metrics("C", message: "no_upload_yet".ls)
    }
    
    class func singleDayPlaceholderMetrics() -> StreamMetrics<PlaceholderView> {
        return metrics("C", message: "no_uploads_for_this_day".ls)
    }
    
    class func searchPlaceholderMetrics() -> StreamMetrics<PlaceholderView> {
        return metrics(":", message: "no_contacts_with_phone_number".ls)
    }
    
    class func sharePlaceholderMetrics() -> StreamMetrics<PlaceholderView> {
        return metrics("C", message: "no_wraps_found".ls)
    }
}

final class HomePlaceholderView: PlaceholderView {
    
    class func homePlaceholderMetrics(actionBlock: (Void -> Void)) -> StreamMetrics<HomePlaceholderView> {
        return StreamMetrics<HomePlaceholderView>(layoutBlock: { $0.actionBlock = actionBlock })
    }
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        textLabel.text = "no_wraps_yet".ls + "\n\n\n" + "easy_create_wrap".ls
        iconLabel.text = "C"
        addSubview(containerView)
        containerView.addSubview(textLabel)
        containerView.addSubview(iconLabel)
        textLabel.textColor = Color.grayDark
        textLabel.preset = Font.Normal.rawValue
        textLabel.font = UIFont.fontWithPreset(.Normal)
        let actionButton = Button(type: .Custom)
        actionButton.setTitle("let's_get_started".ls, forState: .Normal)
        actionButton.backgroundColor = Color.orange
        actionButton.normalColor = Color.orange
        actionButton.highlightedColor = Color.orangeDark
        actionButton.preset = Font.Normal.rawValue
        actionButton.titleLabel?.font = UIFont.fontWithPreset(.Normal)
        actionButton.clipsToBounds = true
        actionButton.cornerRadius = 6
        actionButton.addTarget(self, action: #selector(HomePlaceholderView.action(_:)), forControlEvents: .TouchUpInside)
        containerView.addSubview(actionButton)
        containerView.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self)
        }
        iconLabel.snp_makeConstraints { (make) -> Void in
            make.top.centerX.equalTo(containerView)
            make.bottom.equalTo(textLabel.snp_top)
        }
        textLabel.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.equalTo(containerView)
            make.width.equalTo(250)
            make.bottom.equalTo(actionButton.snp_top).offset(-12)
        }
        actionButton.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(48)
            make.leading.trailing.bottom.equalTo(containerView)
        }
        userInteractionEnabled = true
    }
    
    var actionBlock: (Void -> Void)?
    
    @IBAction func action(sender: AnyObject) {
        actionBlock?()
    }
}