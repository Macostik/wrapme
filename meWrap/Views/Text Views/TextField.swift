//
//  TextField.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class TextField: UITextField {
    
    @IBInspectable var disableSeparator: Bool = false
    @IBInspectable var trim: Bool = false
    @IBInspectable var strokeColor: UIColor?
    @IBInspectable var localize: Bool = false {
        willSet {
            if let text = text where !text.isEmpty {
                super.placeholder = text.ls
            }
        }
    }
    
    @IBInspectable var preset: String? {
        willSet {
            if let font = font, let preset = newValue where !preset.isEmpty {
                self.font = font.fontWithPreset(preset)
                FontPresetter.defaultPresetter.addReceiver(self)
            }
        }
    }
    
    override var text: String? {
        willSet {
            if let text = newValue where !text.isEmpty {
                super.text = text
                sendActionsForControlEvents(.EditingChanged)
            }
        }
    }
    
    override func resignFirstResponder() -> Bool {
        if trim == true, let text = text where !text.isEmpty {
            self.text = text.trim
        }
        
        return super.resignFirstResponder()
    }
    
    override var placeholder: String? {
        willSet {
            if let placeholder = newValue {
                super.placeholder = localize ? placeholder.ls : placeholder
            }
        }
    }
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        guard let preset = preset, let font = font else { return }
        self.font = font.fontWithPreset(preset)
    }
    
    #if !TARGET_INTERFACE_BUILDER
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        if !disableSeparator {
            let path = UIBezierPath()
            path.lineWidth =  Constants.pixelSize
            let y = bounds.height - path.lineWidth/2.0
            path.move(0, y).line(bounds.width, y)
            var placeholderColor = UIColor.clearColor()
            if let strokeColor = strokeColor {
                placeholderColor = strokeColor
            } else {
                if let _placeholderColor = attributedPlaceholder?.attribute(NSForegroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor {
                    placeholderColor = _placeholderColor
                }
            }
            placeholderColor.setStroke()
            path.stroke()
        }
    }
    #endif
}