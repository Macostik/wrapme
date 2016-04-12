//
//  Label.swift
//  meWrap
//
//  Created by Yura Granchenko on 28/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class Label: UILabel {
    
    convenience init(icon: String, size: CGFloat, textColor: UIColor = UIColor.whiteColor()) {
        self.init()
        font = UIFont.icons(size)
        text = icon
        self.textColor = textColor
    }
    
    convenience init(preset: Font, weight: Font.Weight = .Light, textColor: UIColor = Color.grayDarker) {
        self.init()
        font = UIFont.fontWithPreset(preset, weight: weight)
        self.preset = preset.rawValue
        self.textColor = textColor
        FontPresetter.defaultPresetter.addReceiver(self)
    }
    
    @IBInspectable var preset: String? {
        willSet {
            if let preset = newValue where !preset.isEmpty {
                font = font.fontWithPreset(preset)
                FontPresetter.defaultPresetter.addReceiver(self)
            }
        }
    }
    
    @IBInspectable var localize: Bool = false {
        willSet {
            if newValue {
                text = text?.ls
                layoutIfNeeded()
            }
        }
    }
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        guard let preset = preset else { return }
        font = font.fontWithPreset(preset)
    }
}