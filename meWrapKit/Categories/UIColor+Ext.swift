//
//  UIColor+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

struct Color {
    static let grayDarker = UIColor(hex: 0x222222)
    static let grayDark = UIColor(hex: 0x333333)
    static let gray = UIColor(hex: 0x555555)
    static let grayLight = UIColor(hex: 0x777777)
    static let grayLighter = UIColor(hex: 0x999999)
    static let grayLightest = UIColor(hex: 0xeeeeee)
    static let orangeDarker = UIColor(hex: 0xa13e00)
    static let orangeDark = UIColor(hex: 0xcb5309)
    static let orange = UIColor(hex: 0xf37526)
    static let orangeLight = UIColor(hex: 0xff9350)
    static let orangeLighter = UIColor(hex: 0xffac79)
    static let orangeLightest = UIColor(hex: 0xfbd5bd)
    static let dangerRed = UIColor(hex: 0xd9534f)
    static let green = UIColor(hex: 0x5cb85c)
    static let greenOnline = UIColor(hex: 0x66d17a)
    static let purple = UIColor(hex: 0x8878ff)
    static let blue = UIColor(hex: 0x50b5ea)
    static let greenOption = UIColor(hex: 0x32c9ab)
    static let redOption = UIColor(hex: 0xe84b4b)
}

extension UIColor {
    
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255
        let blue = CGFloat(hex & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func colorByAddingValue(value: CGFloat) -> UIColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: max(0, min(1, r + value)), green: max(0, min(1, g + value)), blue: max(0, min(1, b + value)), alpha: max(0, min(1, a + value)))
    }
    
    func lighterColor() -> UIColor {
        return colorByAddingValue(0.2)
    }
    
    func darkerColor() -> UIColor {
        return colorByAddingValue(-0.2)
    }
}