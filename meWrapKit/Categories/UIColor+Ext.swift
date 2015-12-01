//
//  UIColor+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class Color: NSObject {
    static var grayDarker = UIColor(hex: 0x222222, alpha: 1)
    static var grayDark = UIColor(hex: 0x333333, alpha: 1)
    static var gray = UIColor(hex: 0x555555, alpha: 1)
    static var grayLight = UIColor(hex: 0x777777, alpha: 1)
    static var grayLighter = UIColor(hex: 0x999999, alpha: 1)
    static var grayLightest = UIColor(hex: 0xeeeeee, alpha: 1)
    static var orangeDarker = UIColor(hex: 0xa13e00, alpha: 1)
    static var orangeDark = UIColor(hex: 0xcb5309, alpha: 1)
    static var orange = UIColor(hex: 0xf37526, alpha: 1)
    static var orangeLight = UIColor(hex: 0xff9350, alpha: 1)
    static var orangeLighter = UIColor(hex: 0xffac79, alpha: 1)
    static var orangeLightest = UIColor(hex: 0xfbd5bd, alpha: 1)
    static var dangerRed = UIColor(hex: 0xd9534f, alpha: 1)
    static var green = UIColor(hex: 0x5cb85c, alpha: 1)
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