//
//  PlaceholderView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

final class PlaceholderView: UIView {
    
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
            let view = PlaceholderView()
            view.textLabel.text = "no_wraps_yet".ls + "\n\n\n" + "easy_create_wrap".ls
            view.iconLabel.text = "C"
            view.addSubview(view.textLabel)
            view.addSubview(view.iconLabel)
            view.textLabel.textColor = Color.grayDark
            view.textLabel.preset = Font.Normal.rawValue
            view.textLabel.font = UIFont.fontWithPreset(.Normal)
            let actionButton = Button(type: .Custom)
            actionButton.setTitle("let's_get_started".ls, forState: .Normal)
            actionButton.backgroundColor = Color.orange
            actionButton.normalColor = Color.orange
            actionButton.highlightedColor = Color.orangeDark
            actionButton.preset = Font.Normal.rawValue
            actionButton.titleLabel?.font = UIFont.fontWithPreset(.Normal)
            actionButton.clipsToBounds = true
            actionButton.cornerRadius = 6
            actionBlock(actionButton)
            view.addSubview(actionButton)
            view.iconLabel.snp_makeConstraints { (make) -> Void in
                make.top.centerX.equalTo(view)
                make.bottom.equalTo(view.textLabel.snp_top)
            }
            view.textLabel.snp_makeConstraints { (make) -> Void in
                make.leading.trailing.equalTo(view)
                make.width.equalTo(250)
                make.bottom.equalTo(actionButton.snp_top).offset(-12)
            }
            actionButton.snp_makeConstraints { (make) -> Void in
                make.height.equalTo(48)
                make.leading.trailing.bottom.equalTo(view)
            }
            view.userInteractionEnabled = true
            return view
        }
    }
}