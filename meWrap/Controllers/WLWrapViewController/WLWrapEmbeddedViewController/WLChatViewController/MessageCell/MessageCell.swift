//
//  MessageCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class MessageCell: StreamReusableView, EntryNotifying {
    
    @IBOutlet weak var tailView: UIImageView!
    @IBOutlet weak var avatarView: ImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var textView: UILabel!
    @IBOutlet weak var indicator: EntryStatusIndicator!
    
    override func awakeFromNib () {
        super.awakeFromNib()
        FlowerMenu.sharedMenu().registerView(self, constructor: { [weak self] (menu) in
            menu.addCopyAction({ (message) -> Void in
                if let message = message as? Message, let text = message.text where !text.isEmpty {
                    UIPasteboard.generalPasteboard().setValue(text, forPasteboardType: "kUTTypeText")
                }
            })
            menu.entry = self?.entry
            })
        guard let color = textView.superview?.backgroundColor else { return }
        if tailView != nil {
            tailView.image = MessageCell.tailImageWithColor(color, size: tailView.size, drawing: { [weak self] size in
                let path = UIBezierPath()
                if self?.tailView.x > self?.textView.superview?.x {
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
    
    class func tailImageWithColor(color: UIColor, size: CGSize,  drawing: CGSize -> Void) -> UIImage? {
        var tails = NSDictionary()
        var image = tails.objectForKey(color)
        if image == nil {
            image = UIImage.draw(size, opaque: false, scale:  UIScreen.mainScreen().scale, drawing: drawing)
            if tails.count == 0 {
                let _tails = tails.mutableCopy()
                _tails.setObject(image, forKey:color)
                tails = _tails.copy() as! NSDictionary
            } else {
                if let image = image {
                    tails = NSDictionary(object: image, forKey: color)
                }
            }
        }
        return image as? UIImage
    }
    
    override func setup(entry: AnyObject) {
        guard let message = entry as? Message else { return }
        if nameLabel != nil {
           avatarView.url = message.contributor?.avatar?.small
            nameLabel.text = message.contributor?.name
        }
        timeLabel.text = message.createdAt.stringWithDateStyle(.ShortStyle)
        textView.text = message.text
        if indicator != nil {
            indicator.updateStatusIndicator(message)
        }
        FlowerMenu.sharedMenu().hide()
    }
}


