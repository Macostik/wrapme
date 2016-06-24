//
//  TextField.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class TextField: UITextField, FontPresetable {
    
    @IBInspectable var disableSeparator: Bool = false
    @IBInspectable var trim: Bool = false
    @IBInspectable var strokeColor: UIColor?
    weak var highlighLabel: UILabel?
    @IBInspectable var highlightedStrokeColor: UIColor?
    @IBInspectable var localize: Bool = false {
        willSet {
            if let text = placeholder where !text.isEmpty {
                super.placeholder = text.ls
            }
        }
    }
    
    var presetableFont: UIFont? {
        get { return font }
        set { font = newValue }
    }
    
    @IBInspectable var preset: String? {
        willSet {
            makePresetable(newValue)
        }
    }
    
    override var text: String? {
        didSet {
            sendActionsForControlEvents(.EditingChanged)
        }
    }
    
    override func resignFirstResponder() -> Bool {
        if trim == true, let text = text where !text.isEmpty {
            self.text = text.trim
        }
        
        let flag = super.resignFirstResponder()
        setNeedsDisplay()
        return flag
    }
    
    override func becomeFirstResponder() -> Bool {
        let flag = super.becomeFirstResponder()
        setNeedsDisplay()
        return flag
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard !disableSeparator else { return }
        let path = UIBezierPath()
        var placeholderColor: UIColor?
        if isFirstResponder() {
            path.lineWidth = 2
            placeholderColor = highlightedStrokeColor ?? attributedPlaceholder?.foregroundColor
            highlighLabel?.highlighted = true
        } else {
            path.lineWidth = 1
            placeholderColor = strokeColor ?? attributedPlaceholder?.foregroundColor
            highlighLabel?.highlighted = false
        }
        if let color = placeholderColor {
            let y = bounds.height - path.lineWidth/2.0
            path.move(0 ^ y).line(bounds.width ^ y)
            color.setStroke()
            path.stroke()
        }
    }
}

extension NSAttributedString {
    
    var foregroundColor: UIColor? {
        return attribute(NSForegroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor
    }
}