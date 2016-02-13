//
//  EmojiCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class EmojiCell: StreamReusableView {
    @IBOutlet weak var emojiLabel: UILabel?
    
    override func setup(entry: AnyObject?) {
        if let emoji = entry as? String {
            emojiLabel?.text = emoji
        }
    }
}