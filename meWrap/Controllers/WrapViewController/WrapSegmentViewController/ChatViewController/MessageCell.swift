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

final class MessageDateView: StreamReusableView {
    
    private let dateLabel = specify(Label(preset: FontPreset.Normal, weight: .Regular)) { $0.textAlignment = .Center }
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        addSubview(dateLabel)
        dateLabel.snp_makeConstraints(closure: { $0.center.equalTo(self) })
    }
    
    override func setup(entry: AnyObject?) {
        guard let message = entry as? Message else { return }
        dateLabel.text = message.createdAt.stringWithDateStyle(.MediumStyle)
    }
}

class BaseMessageCell: StreamReusableView, FlowerMenuConstructor {
    
    private static let leftTail = UIImage.draw(CGSize(width: 8, height: 10), drawing: { size in
        let path = UIBezierPath()
        path.move(size.width, 0).quadCurve(0, 0, controlX: size.width/2, controlY: size.height/2)
        path.quadCurve(size.width, size.height, controlX: 0, controlY: size.height).line(size.width, 0)
        Color.grayLightest.setFill()
        path.fill()
    })
    
    private static let rightTail = UIImage.draw(CGSize(width: 8, height: 10), drawing: { size in
        let path = UIBezierPath()
        path.move(0, 0).quadCurve(size.width, 0, controlX: size.width/2, controlY: size.height/2)
        path.quadCurve(0, size.height, controlX: size.width, controlY: size.height).line(0, 0)
        Color.orange.setFill()
        path.fill()
    })
    
    internal let timeLabel = Label(preset: .Smaller, textColor: Color.grayLighter)
    internal let textView = specify(SmartLabel(preset: .Normal, weight: .Regular, textColor: UIColor.blackColor())) {
        $0.numberOfLines = 0
    }
    internal let bubbleView = specify(UIView(), {
        $0.cornerRadius = 6
        $0.clipsToBounds = true
        $0.backgroundColor = Color.grayLightest
    })
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        FlowerMenu.sharedMenu.registerView(self)
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        if let message = entry as? Message {
            menu.addCopyAction({ UIPasteboard.generalPasteboard().string = message.text })
        }
    }
    
    override func setup(entry: AnyObject?) {
        guard let message = entry as? Message else { return }
        setupMessage(message)
    }
    
    internal func setupMessage(message: Message) {
        timeLabel.text = message.createdAt.stringWithTimeStyle(.ShortStyle)
        textView.text = message.text
        FlowerMenu.sharedMenu.hide()
    }
}

final class MessageCell: BaseMessageCell {
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        addSubview(bubbleView)
        bubbleView.addSubview(textView)
        bubbleView.addSubview(timeLabel)
        bubbleView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self).inset(64)
            make.trailing.lessThanOrEqualTo(self).inset(16)
            make.top.bottom.equalTo(self)
        }
        textView.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.equalTo(bubbleView).inset(6)
            make.top.equalTo(bubbleView).inset(2)
        }
        timeLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(bubbleView).inset(6)
            make.leading.greaterThanOrEqualTo(bubbleView).inset(6)
            make.top.equalTo(textView.snp_bottom)
            make.bottom.equalTo(bubbleView).inset(4)
        }
    }
}

final class MessageWithNameCell: BaseMessageCell {
    
    private let tailView = UIImageView(image: BaseMessageCell.leftTail)
    private let avatarView = UserAvatarView()
    private let nameLabel = Label(preset: .Smaller, textColor: Color.grayLighter)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        avatarView.cornerRadius = 20
        addSubview(avatarView)
        addSubview(bubbleView)
        bubbleView.addSubview(nameLabel)
        bubbleView.addSubview(textView)
        bubbleView.addSubview(timeLabel)
        addSubview(tailView)
        avatarView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self).inset(16)
            make.top.equalTo(self)
            make.size.equalTo(40)
        }
        bubbleView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatarView.snp_trailing).offset(8)
            make.trailing.lessThanOrEqualTo(self).inset(16)
            make.top.bottom.equalTo(self)
        }
        nameLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(bubbleView).inset(6)
            make.trailing.lessThanOrEqualTo(bubbleView).inset(6)
            make.top.equalTo(bubbleView).inset(4)
        }
        textView.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.equalTo(bubbleView).inset(6)
            make.top.equalTo(nameLabel.snp_bottom).inset(2)
        }
        timeLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(bubbleView).inset(6)
            make.leading.greaterThanOrEqualTo(bubbleView).inset(6)
            make.top.equalTo(textView.snp_bottom)
            make.bottom.equalTo(bubbleView).inset(4)
        }
        tailView.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSize(width: 8, height: 10))
            make.trailing.equalTo(bubbleView.snp_leading)
            make.bottom.equalTo(avatarView.snp_bottom)
        }
    }
    
    override func setupMessage(message: Message) {
        super.setupMessage(message)
        avatarView.user = message.contributor
        nameLabel.text = message.contributor?.name
    }
}

final class MyMessageCell: BaseMessageCell {
    
    private let tailView = UIImageView(image: BaseMessageCell.rightTail)
    private let indicator = EntryStatusIndicator(color: Color.orangeLightest)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        bubbleView.backgroundColor = Color.orange
        textView.textColor = UIColor.whiteColor()
        timeLabel.textColor = Color.orangeLightest
        addSubview(bubbleView)
        bubbleView.addSubview(textView)
        bubbleView.addSubview(timeLabel)
        bubbleView.addSubview(indicator)
        addSubview(tailView)
        bubbleView.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self).inset(16)
            make.leading.greaterThanOrEqualTo(self).inset(16)
            make.top.bottom.equalTo(self)
        }
        textView.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.equalTo(bubbleView).inset(6)
            make.top.equalTo(bubbleView).inset(2)
        }
        timeLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(bubbleView).inset(22)
            make.leading.greaterThanOrEqualTo(bubbleView).inset(6)
            make.top.equalTo(textView.snp_bottom)
            make.bottom.equalTo(bubbleView).inset(4)
        }
        indicator.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(bubbleView).inset(4)
            make.leading.equalTo(timeLabel.snp_trailing)
            make.centerY.height.equalTo(timeLabel)
        }
        tailView.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSize(width: 8, height: 10))
            make.leading.equalTo(bubbleView.snp_trailing)
            make.bottom.equalTo(bubbleView.snp_bottom).inset(5)
        }
    }
    
    override func setupMessage(message: Message) {
        super.setupMessage(message)
        indicator.updateStatusIndicator(message)
        tailView.hidden = !message.chatMetadata.isGroup
    }
}
