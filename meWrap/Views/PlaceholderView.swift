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
    
    class func placeholderLoader(iconName: String, message: String) -> StreamLoader<PlaceholderView> {
        return StreamLoader<PlaceholderView>(layoutBlock: { view in
            view.textLabel.text = message
            view.iconLabel.text = iconName
        })
    }
    
    let containerView = UIView()
    
    let textLabel: Label = {
        let label = Label(preset: .Larger, weight: UIFontWeightLight, textColor: Color.grayLighter)
        label.numberOfLines = 0
        label.textAlignment = .Center
        return label
    }()
    let iconLabel = Label(icon: "", size: 96, textColor: Color.grayLighter)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
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
    
    class func chatPlaceholderLoader() -> StreamLoader<PlaceholderView> {
        return placeholderLoader("7", message: "")
    }
    
    class func commentsPlaceholderMetrics() -> StreamMetrics {
        return StreamMetrics(loader: commentsPlaceholderLoader())
    }
    
    class func commentsPlaceholderLoader() -> StreamLoader<PlaceholderView> {
        return placeholderLoader("q", message: "no_comments_yet".ls)
    }
    
    class func hottestPlaceholderLoader() -> StreamLoader<PlaceholderView> {
        return placeholderLoader("C", message: "coming_soon".ls)
    }
    
    class func inboxPlaceholderLoader() -> StreamLoader<PlaceholderView> {
        return placeholderLoader("J", message: "inbox_placeholder".ls)
    }
    
    class func mediaPlaceholderLoader() -> StreamLoader<PlaceholderView> {
        return placeholderLoader("C", message: "no_upload_yet".ls)
    }
    
    class func singleDayPlaceholderLoader() -> StreamLoader<PlaceholderView> {
        return placeholderLoader("C", message: "no_uploads_for_this_day".ls)
    }
    
    class func searchPlaceholderLoader() -> StreamLoader<PlaceholderView> {
        return placeholderLoader(":", message: "no_contacts_with_phone_number".ls)
    }
    
    class func sharePlaceholderLoader() -> StreamLoader<PlaceholderView> {
        return placeholderLoader("C", message: "easy_create_wrap".ls)
    }
}

final class HomePlaceholderView: PlaceholderView {
    
    class func homePlaceholderLoader(actionBlock: (Void -> Void)) -> StreamLoader<HomePlaceholderView> {
        return StreamLoader<HomePlaceholderView>(layoutBlock: { $0.actionBlock = actionBlock })
    }
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        textLabel.text = "easy_create_wrap".ls
        iconLabel.text = "C"
        addSubview(containerView)
        containerView.addSubview(textLabel)
        containerView.addSubview(iconLabel)
        textLabel.textColor = Color.grayDark
        textLabel.preset = FontPreset.Normal.rawValue
        textLabel.font = UIFont.fontWithPreset(.Normal, weight: UIFontWeightLight)
        let actionButton = Button(type: .Custom)
        actionButton.setTitle("let's_get_started".ls, forState: .Normal)
        actionButton.backgroundColor = Color.orange
        actionButton.normalColor = Color.orange
        actionButton.highlightedColor = Color.orangeDark
        actionButton.preset = FontPreset.Normal.rawValue
        actionButton.titleLabel?.font = UIFont.fontWithPreset(.Normal, weight: UIFontWeightLight)
        actionButton.clipsToBounds = true
        actionButton.cornerRadius = 6
        actionButton.addTarget(self, action: #selector(HomePlaceholderView.action(_:)), forControlEvents: .TouchUpInside)
        containerView.addSubview(actionButton)
        containerView.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self)
        }
        iconLabel.snp_makeConstraints { (make) -> Void in
            make.top.centerX.equalTo(containerView)
            make.bottom.equalTo(textLabel.snp_top).offset(-100)
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
    }
    
    var actionBlock: (Void -> Void)?
    
    @IBAction func action(sender: AnyObject) {
        actionBlock?()
    }
}