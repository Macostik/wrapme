//
//  Label.swift
//  meWrap
//
//  Created by Yura Granchenko on 28/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class Label: UILabel {
    
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
                if let text = text where !text.isEmpty {
                    super.text = text.ls
                }
            }
        }
    }
    
    override var text: String? {
        willSet {
            if let text = newValue where !text.isEmpty {
                super.text = localize ? text.ls : text
            }
        }
    }
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        guard let preset = preset else { return }
        font = font.fontWithPreset(preset)
    }
}