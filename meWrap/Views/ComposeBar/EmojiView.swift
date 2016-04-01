//
//  EmojiView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

private var MaxRecentEmojisCount = 21

class EmojiCell: StreamReusableView {
    
    private var emojiLabel: UILabel = UILabel()
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        emojiLabel.font = UIFont.systemFontOfSize(34)
        addSubview(emojiLabel)
        emojiLabel.snp_makeConstraints { $0.center.equalTo(self) }
    }
    
    override func setup(entry: AnyObject?) {
        emojiLabel.text = entry as? String
    }
}

private enum Emoji: Int {
    
    case PeopleAndSmiles, Nature, FoodAndDrinks, Activity, TravelAndPlaces, Objects, Symbols, Flags
    
    static func recentEmojis() -> [String]? {
        return NSUserDefaults.standardUserDefaults().recentEmojis
    }
    
    static func emojiStrings(emoji: Emoji) -> [String]? {
        return NSArray.plist(emoji.stringValue()) as? [String]
    }
    
    static func saveRecent(emoji: String) {
        var recentEmojis = NSUserDefaults.standardUserDefaults().recentEmojis ?? [String]()
        if let index = recentEmojis.indexOf(emoji) {
            recentEmojis.removeAtIndex(index)
        }
        recentEmojis.insert(emoji, atIndex: 0)
        if recentEmojis.count > MaxRecentEmojisCount {
            recentEmojis.removeLast()
        }
        NSUserDefaults.standardUserDefaults().recentEmojis = recentEmojis
    }
    
    func stringValue() -> String {
        switch self {
        case PeopleAndSmiles: if #available(iOS 9.0, *) { return "peopleAndSmiles_iOS_9" } else { return "peopleAndSmiles_iOS_8" }
        case Nature: if #available(iOS 9.0, *) { return "nature_iOS_9" } else { return "nature_iOS_8" }
        case FoodAndDrinks: if #available(iOS 9.0, *) { return "foodAndDrinks_iOS_9" } else { return "foodAndDrinks_iOS_8" }
        case Activity: if #available(iOS 9.0, *) { return "activity_iOS_9" } else { return "activity_iOS_8" }
        case TravelAndPlaces: if #available(iOS 9.0, *) { return "travelAndPlaces_iOS_9" } else { return "travelAndPlaces_iOS_8" }
        case Objects: if #available(iOS 9.0, *) { return "objects_iOS_9" } else { return "objects_iOS_8" }
        case Symbols: if #available(iOS 9.0, *) { return "symbols_iOS_9" } else { return "symbols_iOS_8" }
        case Flags: if #available(iOS 9.0, *) { return "flags_iOS_9" } else { return "flags_iOS_8" }
        }
    }
}

class EmojiView: UIView {
    
    @IBOutlet weak var streamView: StreamView!
    
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    weak var composeBar: ComposeBar!
    
    var dataSource: StreamDataSource!
    
    private var emojis: [String]? {
        willSet {
            dataSource.items = newValue
        }
    }
    
    class func emojiView(composeBar: ComposeBar) -> EmojiView {
        let emojiView: EmojiView! = loadFromNib("EmojiView")
        emojiView.composeBar = composeBar
        emojiView.backgroundColor = composeBar.backgroundColor
        return emojiView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        streamView.layout = HorizontalGridLayout()
        dataSource = StreamDataSource(streamView: streamView)
        let metrics = StreamMetrics(loader: StreamLoader<EmojiCell>())
        metrics.modifyItem = { [weak self] item in
            if let streamView = self?.streamView {
                item.ratio = (streamView.height/5) / (streamView.width/8)
            }
        }
        metrics.selection = { [weak self] (item, emoji) -> Void in
            let emoji = emoji as! String
            Emoji.saveRecent(emoji)
            self?.composeBar.textView.insertText(emoji)
        }
        dataSource.addMetrics(metrics)
        dataSource.numberOfGridColumns = 5
        dataSource.sizeForGridColumns = 0.2
        if let recentEmojis = Emoji.recentEmojis() where recentEmojis.count > 0 {
            emojis = recentEmojis
        } else {
            segmentedControl.selectedSegment = 1
            emojis = Emoji.emojiStrings(.PeopleAndSmiles)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        UIView.performWithoutAnimation { self.streamView.reload() }
    }
    
    @IBAction func returnClicked(sender: UIButton) {
        composeBar.textView.deleteBackward()
    }
    
    @IBAction func returnKeyboard(sender: UIButton) {
        composeBar.isEmojiKeyboardActive = false
    }
}

extension EmojiView: SegmentedControlDelegate {
    func segmentedControl(control: SegmentedControl, didSelectSegment segment: Int) {
        streamView.contentOffset = CGPointZero
        if segment == 0 {
            emojis = Emoji.recentEmojis()
        } else if let emoji = Emoji(rawValue: segment - 1) {
            emojis = Emoji.emojiStrings(emoji)
        }
    }
}