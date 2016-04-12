//
//  UIFont+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/21/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

func +(preset: Font, weight: Font.Weight) -> UIFont {
    return UIFont.fontWithPreset(preset, weight: weight)
}

enum Font: String {
    
    enum Weight {
        case Light, Regular, Bold
        func value() -> CGFloat {
            switch self {
            case Light: return UIFontWeightLight
            case Regular: return UIFontWeightRegular
            case Bold: return UIFontWeightBold
            }
        }
    }
    
    case XSmall = "xsmall"
    case Smaller = "smaller"
    case Small = "small"
    case Normal = "normal"
    case Large = "large"
    case Larger = "larger"
    case XLarge = "xlarge"
}

extension UIFont {
    private static let sizes: Dictionary<Font, CGFloat> = [
        .XSmall:11,
        .Smaller:13,
        .Small:15,
        .Normal:17,
        .Large:19,
        .Larger:21,
        .XLarge:23]
    
    private class func sizeWithPreset(preset: Font) -> CGFloat {
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
    
    class func fontWithPreset(preset: Font, weight: Font.Weight = .Light) -> UIFont {
        return UIFont.systemFontOfSize(UIFont.sizeWithPreset(preset), weight: weight.value())
    }
    
    func fontWithPreset(preset: String) -> UIFont? {
        guard let preset = Font(rawValue: preset) else { return nil }
        switch self.fontName {
        case let fontName where fontName.hasSuffix("Regular"):
            return UIFont.fontWithPreset(preset, weight: .Regular)
        case let fontName where fontName.hasSuffix("Light"):
            return UIFont.fontWithPreset(preset)
        default:
            return UIFont(name: fontName, size: UIFont.sizeWithPreset(preset))
        }
    }
    
    class func icons(size: CGFloat) -> UIFont! {
        return UIFont(name: "icons", size: size)
    }
}

extension UIFont {
    class func fontXSmall() -> UIFont { return fontWithPreset(.XSmall, weight: .Regular) }
    class func fontSmaller() -> UIFont { return fontWithPreset(.Smaller, weight: .Regular) }
    class func fontSmall() -> UIFont { return fontWithPreset(.Small, weight: .Regular) }
    class func fontNormal() -> UIFont { return fontWithPreset(.Normal, weight: .Regular) }
    class func fontLarge() -> UIFont { return fontWithPreset(.Large, weight: .Regular) }
    class func fontLarger() -> UIFont { return fontWithPreset(.Larger, weight: .Regular) }
    class func fontXLarge() -> UIFont { return fontWithPreset(.XLarge, weight: .Regular) }
}

extension UIFont {
    class func lightFontXSmall() -> UIFont { return fontWithPreset(.XSmall) }
    class func lightFontSmaller() -> UIFont { return fontWithPreset(.Smaller) }
    class func lightFontSmall() -> UIFont { return fontWithPreset(.Small) }
    class func lightFontNormal() -> UIFont { return fontWithPreset(.Normal) }
    class func lightFontLarge() -> UIFont { return fontWithPreset(.Large) }
    class func lightFontLarger() -> UIFont { return fontWithPreset(.Larger) }
    class func lightFontXLarge() -> UIFont { return fontWithPreset(.XLarge) }
}
