//
//  UIFont+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/21/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

enum FontPreset: String {
    case XSmall = "xsmall"
    case Smaller = "smaller"
    case Small = "small"
    case Normal = "normal"
    case Large = "large"
    case Larger = "larger"
    case XLarge = "xlarge"
}

extension UIFont {
    static let sizes: Dictionary<FontPreset, CGFloat> = [
        .XSmall:11,
        .Smaller:13,
        .Small:15,
        .Normal:17,
        .Large:19,
        .Larger:21,
        .XLarge:23]
    
    private class func sizeWithPreset(preset: FontPreset) -> CGFloat {
        if var size = sizes[preset] {
            let screen = UIScreen.mainScreen()
            if screen.bounds.size.width * screen.scale >= 1080 {
                size += 2
            }
            if let adjustment = adjustments[UIApplication.sharedApplication().preferredContentSizeCategory] {
                size += adjustment
            }
            return size
        } else {
            return UIFont.systemFontSize()
        }
    }
    
    class func sizeWithPreset(preset: String) -> CGFloat {
        if let preset = FontPreset(rawValue: preset) {
            return sizeWithPreset(preset)
        } else {
            return UIFont.systemFontSize()
        }
    }
    
    private class func fontWithName(fontName: String, preset: FontPreset) -> UIFont? {
        return UIFont(name: fontName, size: sizeWithPreset(preset))
    }
    
    class func fontWithName(fontName: String, preset: String) -> UIFont? {
        return UIFont(name: fontName, size: sizeWithPreset(preset))
    }
    
    private static let adjustments: Dictionary<String, CGFloat> = [
        UIContentSizeCategoryExtraSmall:-3,
        UIContentSizeCategorySmall: -2,
        UIContentSizeCategoryMedium:-1,
        UIContentSizeCategoryLarge:0,
        UIContentSizeCategoryExtraLarge:1,
        UIContentSizeCategoryExtraExtraLarge:2,
        UIContentSizeCategoryExtraExtraExtraLarge:3]
    
    private class func fontWithPreset(preset: FontPreset) -> UIFont? {
        return UIFont.systemFontOfSize(sizeWithPreset(preset))
    }
    
    class func fontWithPreset(preset: String) -> UIFont? {
        return UIFont.systemFontOfSize(sizeWithPreset(preset))
    }
    
    private class func lightFontWithPreset(preset: FontPreset) -> UIFont? {
        return UIFont.fontWithName("HelveticaNeue-Light", preset: preset)
    }
    
    class func lightFontWithPreset(preset: String) -> UIFont? {
        return UIFont.fontWithName("HelveticaNeue-Light", preset: preset)
    }
    
    func fontWithPreset(preset: String) -> UIFont? {
        return UIFont.systemFontOfSize(UIFont.sizeWithPreset(preset))
    }
}

extension UIFont {
    class func fontXSmall() -> UIFont? {
        return UIFont.fontWithPreset(.XSmall)
    }
    class func fontSmaller() -> UIFont? {
        return UIFont.fontWithPreset(.Smaller)
    }
    class func fontSmall() -> UIFont? {
        return UIFont.fontWithPreset(.Small)
    }
    class func fontNormal() -> UIFont? {
        return UIFont.fontWithPreset(.Normal)
    }
    class func fontLarge() -> UIFont? {
        return UIFont.fontWithPreset(.Large)
    }
    class func fontLarger() -> UIFont? {
        return UIFont.fontWithPreset(.Larger)
    }
    class func fontXLarge() -> UIFont? {
        return UIFont.fontWithPreset(.XLarge)
    }
}

extension UIFont {
    class func lightFontXSmall() -> UIFont? {
        return UIFont.lightFontWithPreset(.XSmall)
    }
    class func lightFontSmaller() -> UIFont? {
        return UIFont.lightFontWithPreset(.Smaller)
    }
    class func lightFontSmall() -> UIFont? {
        return UIFont.lightFontWithPreset(.Small)
    }
    class func lightFontNormal() -> UIFont? {
        return UIFont.lightFontWithPreset(.Normal)
    }
    class func lightFontLarge() -> UIFont? {
        return UIFont.lightFontWithPreset(.Large)
    }
    class func lightFontLarger() -> UIFont? {
        return UIFont.lightFontWithPreset(.Larger)
    }
    class func lightFontXLarge() -> UIFont? {
        return UIFont.lightFontWithPreset(.XLarge)
    }
}
