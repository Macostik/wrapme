//
//  TextView.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class TextView: UITextView {
    
    @IBInspectable var trim: Bool = false
    
    @IBInspectable var preset: String? {
        willSet {
            if let font = font, let preset = newValue where !preset.isEmpty {
                self.font = font.fontWithPreset(preset)
                FontPresetter.defaultPresetter.addReceiver(self)
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.textDidChange), name: UITextViewTextDidChangeNotification, object: self)
        if editable && dataDetectorTypes != .None {
            dataDetectorTypes = .All
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.textDidChange), name: UITextViewTextDidChangeNotification, object: self)
        if editable && dataDetectorTypes != .None {
            dataDetectorTypes = .All
        }
    }
    
    override var text: String! {
        didSet {
            textDidChange()
        }
    }
    
    final func textDidChange() {
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        if let placeholder = placeholder where text.isEmpty {
            let attributes = [NSFontAttributeName: self.font!, NSForegroundColorAttributeName: Color.grayLighter]
            let size = placeholder.sizeWithAttributes(attributes)
            placeholder.drawAtPoint(0 ^ (height/2 - size.height/2), withAttributes: attributes)
        }
    }
    
    var placeholder: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func resignFirstResponder() -> Bool {
        if trim == true, let text = text where !text.isEmpty {
            self.text = text.trim
        }
        
        return super.resignFirstResponder()
    }
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        guard let preset = preset, let font = font else { return }
        self.font = font.fontWithPreset(preset)
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if editable || dataDetectorTypes == .None { return super.pointInside(point, withEvent: event) }
        let dataDetector = try? NSDataDetector(types: NSTextCheckingAllTypes)
        if let resultsString = dataDetector?.matchesInString(text, options: .ReportProgress, range: NSMakeRange(0, text.characters.count)) {
            for result in resultsString {
                let range = result.range
                var insideFlag = false
                layoutManager.enumerateEnclosingRectsForGlyphRange(range, withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0), inTextContainer: textContainer, usingBlock: { (rect, stop) -> Void in
                    insideFlag = CGRectContainsPoint(rect, point)
                    if insideFlag {
                        stop.memory = true
                    }
                })
                return insideFlag
            }
        }
        return false
    }
}