//
//  MessageCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import MobileCoreServices

final class MessageDateView: StreamReusableView {
    
    class func layoutMetrics() -> StreamMetrics {
        return StreamMetrics(loader: LayoutStreamLoader<MessageDateView>(), size: 33)
    }
    
    weak var dateLabel: Label!
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let label = Label(preset: FontPreset.Normal, weight: UIFontWeightRegular)
        label.textAlignment = .Center
        addSubview(label)
        dateLabel = label
        label.snp_makeConstraints(closure: { $0.center.equalTo(self) })
    }
    
    override func setup(entry: AnyObject?) {
        guard let message = entry as? Message else { return }
        dateLabel.text = message.createdAt.stringWithDateStyle(.MediumStyle)
    }
}

final class MessageCell: StreamReusableView {
    
    @IBOutlet weak var tailView: UIImageView?
    @IBOutlet weak var avatarView: ImageView?
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var textView: UILabel!
    @IBOutlet weak var indicator: EntryStatusIndicator?
    
    override func awakeFromNib () {
        super.awakeFromNib()
        FlowerMenu.sharedMenu().registerView(self, constructor: { [weak self] (menu) in
            menu.addCopyAction({ (message) -> Void in
                if let message = message as? Message, let text = message.text where !text.isEmpty {
                    UIPasteboard.generalPasteboard().setValue(text, forPasteboardType: kUTTypeText as String)
                }
            })
            menu.entry = self?.entry
            })
        if let tailView = tailView, let color = textView.superview?.backgroundColor {
            tailView.image = MessageCell.tailImageWithColor(color, size: tailView.size, drawing: { size in
                let path = UIBezierPath()
                if tailView.x > textView.superview?.x {
                    path.move(0, 0).quadCurve(size.width, 0, controlX: size.width/2, controlY: size.height/2)
                    path.quadCurve(0, size.height, controlX: size.width, controlY: size.height).line(0, 0)
                } else {
                    path.move(size.width, 0).quadCurve(0, 0, controlX: size.width/2, controlY: size.height/2)
                    path.quadCurve(size.width, size.height, controlX: 0, controlY: size.height).line(size.width, 0)
                }
                color.setFill()
                path.fill()
                })
        }
    }
    
    private static var tails = [UIColor:UIImage]()
    
    private class func tailImageWithColor(color: UIColor, size: CGSize, @noescape drawing: CGSize -> Void) -> UIImage? {
        if let image = tails[color] {
            return image
        } else {
            let image = UIImage.draw(size, opaque: false, scale:  UIScreen.mainScreen().scale, drawing: drawing)
            tails[color] = image
            return image
        }
    }
    
    override func setup(entry: AnyObject?) {
        guard let message = entry as? Message else { return }
        if nameLabel != nil {
            avatarView?.url = message.contributor?.avatar?.small
            nameLabel?.text = message.contributor?.name
        }
        timeLabel.text = message.createdAt.stringWithTimeStyle(.ShortStyle)
        textView.text = message.text
        indicator?.updateStatusIndicator(message)
        FlowerMenu.sharedMenu().hide()
    }
}


