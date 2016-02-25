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
    private static let sizes: Dictionary<FontPreset, CGFloat> = [
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
    
    private static let adjustments: Dictionary<String, CGFloat> = [
        UIContentSizeCategoryExtraSmall:-3,
        UIContentSizeCategorySmall: -2,
        UIContentSizeCategoryMedium:-1,
        UIContentSizeCategoryLarge:0,
        UIContentSizeCategoryExtraLarge:1,
        UIContentSizeCategoryExtraExtraLarge:2,
        UIContentSizeCategoryExtraExtraExtraLarge:3]
    
    private class func regularFontWithPreset(preset: FontPreset) -> UIFont {
        return fontWithPreset(preset, weight: UIFontWeightRegular)
    }
    
    private class func lightFontWithPreset(preset: FontPreset) -> UIFont {
        return fontWithPreset(preset, weight: UIFontWeightLight)
    }
    
    class func fontWithPreset(preset: FontPreset, weight: CGFloat) -> UIFont {
        return UIFont.systemFontOfSize(UIFont.sizeWithPreset(preset), weight: weight)
    }
    
    func fontWithPreset(preset: String) -> UIFont? {
        guard let preset = FontPreset(rawValue: preset) else { return nil }
        switch self.fontName {
        case let fontName where fontName.hasSuffix("Regular"):
            return UIFont.regularFontWithPreset(preset)
        case let fontName where fontName.hasSuffix("Light"):
            return UIFont.lightFontWithPreset(preset)
        default:
            return UIFont(name: fontName, size: UIFont.sizeWithPreset(preset))
        }
    }
}

extension UIFont {
    class func fontXSmall() -> UIFont { return regularFontWithPreset(.XSmall) }
    class func fontSmaller() -> UIFont { return regularFontWithPreset(.Smaller) }
    class func fontSmall() -> UIFont { return regularFontWithPreset(.Small) }
    class func fontNormal() -> UIFont { return regularFontWithPreset(.Normal) }
    class func fontLarge() -> UIFont { return regularFontWithPreset(.Large) }
    class func fontLarger() -> UIFont { return regularFontWithPreset(.Larger) }
    class func fontXLarge() -> UIFont { return regularFontWithPreset(.XLarge) }
}

extension UIFont {
    class func lightFontXSmall() -> UIFont { return lightFontWithPreset(.XSmall) }
    class func lightFontSmaller() -> UIFont { return lightFontWithPreset(.Smaller) }
    class func lightFontSmall() -> UIFont { return lightFontWithPreset(.Small) }
    class func lightFontNormal() -> UIFont { return lightFontWithPreset(.Normal) }
    class func lightFontLarge() -> UIFont { return lightFontWithPreset(.Large) }
    class func lightFontLarger() -> UIFont { return lightFontWithPreset(.Larger) }
    class func lightFontXLarge() -> UIFont { return lightFontWithPreset(.XLarge) }
}
