//
//  Emoji.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

private var MaxRecentEmojisCount = 21

enum Emoji: Int {
    
    case Smiles, Flowers, Rings, Cars, Numbers
    
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
            recentEmojis.insert(emoji, atIndex: 0)
        } else {
            recentEmojis.insert(emoji, atIndex: 0)
            if recentEmojis.count > MaxRecentEmojisCount {
                recentEmojis.removeLast()
            }
        }
        NSUserDefaults.standardUserDefaults().recentEmojis = recentEmojis
    }
    
    func stringValue() -> String {
        switch self {
        case Smiles:
            return "smiles"
        case Flowers:
            return "flowers"
        case Rings:
            return "rings"
        case Cars:
            return "cars"
        case Numbers:
            return "numbers"
        }
    }
    
}