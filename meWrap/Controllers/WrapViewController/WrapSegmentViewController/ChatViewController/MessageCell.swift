//
//  MessageCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import MobileCoreServices
import SnapKit

final class MessageDateView: EntryStreamReusableView<Message> {
    
    private let dateLabel = Label(preset: .Smaller, weight: .Regular, textColor: UIColor(white: 0, alpha: 0.87))
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        add(dateLabel) { $0.center.equalTo(self) }
        backgroundColor = Color.grayLightest
    }
    
    override func setup(message: Message) {
        dateLabel.text = message.createdAt.stringWithDateStyle(.MediumStyle)
    }
}

final class MessageBubbleView: UIView {
    
    var isGroup = false
    var isGroupEnd = false
    var containsName = false
    
    var isRightSide = false
    
    var fillColor: UIColor?
    var strokeColor: UIColor?
    
    private func corners() -> UIRectCorner {
        if isGroup {
            if isGroupEnd {
                if containsName {
                    return [.TopRight, .BottomLeft, .BottomRight]
                } else {
                    return .AllCorners
                }
            } else {
                if containsName {
                    return [.TopRight, .BottomRight]
                } else {
                    return [.TopLeft, .TopRight, .BottomLeft]
                }
            }
        } else if isGroupEnd {
            return isRightSide ? [.BottomLeft, .BottomRight, .TopLeft] : [.BottomLeft, .BottomRight, .TopRight]
        } else {
            return isRightSide ? [.BottomLeft, .TopLeft] : [.BottomRight, .TopRight]
        }
    }
    
    override func drawRect(rect: CGRect) {
        let lineWidth: CGFloat = 1/UIScreen.mainScreen().scale
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: lineWidth/2, dy: lineWidth/2), byRoundingCorners: corners(), cornerRadii: 14 ^ 14)
        if let fillColor = fillColor {
            fillColor.setFill()
            path.fill()
        }
        if let strokeColor = strokeColor {
            path.lineWidth = lineWidth
            strokeColor.setStroke()
            path.stroke()
        }
    }
}

class BaseMessageCell: EntryStreamReusableView<Message>, FlowerMenuConstructor {
    
    internal let timeLabel = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    internal let textView = specify(SmartLabel(preset: .Normal, weight: .Regular, textColor: UIColor.blackColor())) {
        $0.numberOfLines = 0
    }
    internal let bubbleView = specify(MessageBubbleView(), {
        $0.clipsToBounds = true
        $0.backgroundColor = UIColor.clearColor()
    })
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        FlowerMenu.sharedMenu.registerView(self)
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        if let message = entry {
            menu.addCopyAction({ UIPasteboard.generalPasteboard().string = message.text })
        }
    }
    
    override func setup(message: Message) {
        setupMessage(message)
    }
    
    internal func setupMessage(message: Message) {
        timeLabel.text = message.createdAt.stringWithTimeStyle(.ShortStyle)
        textView.text = message.text
        FlowerMenu.sharedMenu.hide()
        bubbleView.isGroup = message.chatMetadata.isGroup
        bubbleView.isGroupEnd = message.chatMetadata.isGroupEnd
        bubbleView.containsName = message.chatMetadata.containsName
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bubbleView.setNeedsDisplay()
    }
}

final class MessageCell: BaseMessageCell {
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        super.layoutWithMetrics(metrics)
        bubbleView.strokeColor = UIColor(hex: 0xc3c3c3)
        bubbleView.fillColor = UIColor.whiteColor()
        add(bubbleView) { (make) -> Void in
            make.leading.equalTo(self).offset(64)
            make.trailing.lessThanOrEqualTo(self).offset(-64)
            make.top.equalTo(self)
            make.width.greaterThanOrEqualTo(50)
        }
        bubbleView.add(textView) { (make) -> Void in
            make.top.equalTo(bubbleView).offset(12)
            make.leading.equalTo(bubbleView).offset(16)
            make.trailing.equalTo(bubbleView).offset(-16)
            make.bottom.equalTo(bubbleView).offset(-12)
        }
        add(timeLabel) { (make) -> Void in
            make.leading.equalTo(bubbleView.snp_trailing).offset(12)
            make.centerY.equalTo(bubbleView)
        }
    }
}

final class MessageWithNameCell: BaseMessageCell {
    
    private let avatarView = UserAvatarView(cornerRadius: 20)
    private let nameLabel = Label(preset: .Small, weight: .Regular, textColor: Color.grayLighter)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        super.layoutWithMetrics(metrics)
        bubbleView.strokeColor = UIColor(hex: 0xc3c3c3)
        bubbleView.fillColor = UIColor.whiteColor()
        add(avatarView) { (make) -> Void in
            make.leading.equalTo(self).offset(16)
            make.top.equalTo(self)
            make.size.equalTo(40)
        }
        
        add(bubbleView) { (make) -> Void in
            make.leading.equalTo(self).offset(64)
            make.trailing.lessThanOrEqualTo(self).offset(-64)
            make.top.equalTo(self)
            make.width.greaterThanOrEqualTo(50)
        }
        
        bubbleView.add(nameLabel) { (make) -> Void in
            make.leading.equalTo(bubbleView).offset(16)
            make.trailing.lessThanOrEqualTo(bubbleView).offset(-16)
            make.top.equalTo(bubbleView).offset(12)
        }
        
        bubbleView.add(textView) { (make) -> Void in
            make.top.equalTo(nameLabel.snp_bottom).offset(8)
            make.leading.equalTo(bubbleView).offset(16)
            make.trailing.equalTo(bubbleView).offset(-16)
            make.bottom.equalTo(bubbleView).offset(-12)
        }
        add(timeLabel) { (make) -> Void in
            make.leading.equalTo(bubbleView.snp_trailing).offset(12)
            make.centerY.equalTo(bubbleView)
        }
    }
    
    override func setupMessage(message: Message) {
        super.setupMessage(message)
        avatarView.user = message.contributor
        nameLabel.text = message.contributor?.name
    }
}

final class MyMessageCell: BaseMessageCell {
    
    private let indicator = EntryStatusIndicator(color: Color.orange)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        super.layoutWithMetrics(metrics)
        bubbleView.fillColor = Color.orange
        bubbleView.isRightSide = true
        textView.textColor = UIColor.whiteColor()
        add(bubbleView) { (make) -> Void in
            make.trailing.equalTo(self).offset(-16)
            make.leading.greaterThanOrEqualTo(self).offset(64)
            make.top.equalTo(self)
            make.width.greaterThanOrEqualTo(50)
        }
        bubbleView.add(textView) { (make) -> Void in
            make.top.equalTo(bubbleView).offset(12)
            make.leading.equalTo(bubbleView).offset(16)
            make.trailing.equalTo(bubbleView).offset(-16)
            make.bottom.equalTo(bubbleView).offset(-12)
        }
        add(timeLabel) { (make) -> Void in
            make.trailing.equalTo(bubbleView.snp_leading).offset(-12)
            make.centerY.equalTo(bubbleView)
        }
        add(indicator) { (make) -> Void in
            make.trailing.equalTo(timeLabel.snp_leading).offset(-2)
            make.centerY.equalTo(timeLabel)
        }
    }
    
    override func setupMessage(message: Message) {
        super.setupMessage(message)
        indicator.updateStatusIndicator(message)
    }
}
