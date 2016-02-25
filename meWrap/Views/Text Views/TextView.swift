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
    
    @IBOutlet weak var placeholderLabel: UILabel?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textDidChange", name: UITextViewTextDidChangeNotification, object: self)
        if editable && dataDetectorTypes != .None {
            dataDetectorTypes = .All
        }
    }
    
    override var hidden: Bool {
        willSet {
            super.hidden = newValue
            placeholderLabel?.hidden = newValue
        }
    }
    
    override var text: String! {
        didSet {
            textDidChange()
        }
    }
    
    final func textDidChange() {
        placeholderLabel?.hidden = !text.isEmpty
    }
    
    var placeholder: String? {
        set {
            placeholderLabel?.text = newValue
        }
        get {
            return placeholderLabel?.text
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