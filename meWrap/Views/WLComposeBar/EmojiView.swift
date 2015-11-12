//
//  EmojiView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class EmojiView: UIView {
    
    @IBOutlet weak var streamView: StreamView!
    
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    weak var textView: UITextView!
    
    var dataSource: StreamDataSource!
    
    private var emojis: [String]? {
        didSet {
            dataSource.items = emojis
        }
    }
    
    class func emojiViewWithTextView(textView: UITextView) -> EmojiView? {
        if let emojiView = NSBundle.mainBundle().loadNibNamed("EmojiView", owner: nil, options: nil).first as? EmojiView {
            emojiView.textView = textView
            return emojiView
        } else {
            return nil
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        streamView.layout = GridLayout(horizontal: true)
        dataSource = StreamDataSource(streamView: streamView)
        let metrics = GridMetrics(identifier: "EmojiCell")
        metrics.ratioAt = {[unowned self] (position, metrics) -> CGFloat in
            return (self.streamView.height/3) / (self.streamView.width/7)
        }
        metrics.selection = {[unowned self] (item, emoji) -> Void in
            let emoji = emoji as! String
            Emoji.saveRecent(emoji)
            self.textView.insertText(emoji)
        }
        dataSource.addMetrics(metrics)
        dataSource.numberOfGridColumns = 3
        dataSource.sizeForGridColumns = 0.3333
        
        if let recentEmojis = Emoji.recentEmojis() where recentEmojis.count > 0 {
            emojis = recentEmojis
        } else {
            segmentedControl.selectedSegment = 1;
            emojis = Emoji.emojiStrings(.Smiles)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        UIView.performWithoutAnimation { () -> Void in
            self.streamView.reload()
        }
    }
    
    @IBAction func returnClicked(sender: UIButton) {
        textView.deleteBackward()
    }
}

extension EmojiView: SegmentedControlDelegate {
    func segmentedControl(control: SegmentedControl!, didSelectSegment segment: Int) {
        streamView.contentOffset = CGPointZero
        if segment == 0 {
            emojis = Emoji.recentEmojis()
        } else if let emoji = Emoji(rawValue: segment - 1) {
            emojis = Emoji.emojiStrings(emoji)
        }
    }
}