//
//  TextView.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class TextView: UITextView, FontPresetable {
    
    @IBInspectable var trim: Bool = false
    
    var presetableFont: UIFont? {
        get { return font }
        set { font = newValue }
    }
    var contentSizeCategoryObserver: NotificationObserver?
    
    @IBInspectable var preset: String? {
        willSet {
            makePresetable(newValue)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        awake()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        awake()
    }
    
    func awake() {
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
        updatePlaceholder()
    }
    
    private lazy var placeholderLabel: UILabel = specify(UILabel()) { label in
        self.addSubview(label)
        label.snp_makeConstraints {
            $0.leading.centerY.equalTo(self)
        }
    }
    
    private func updatePlaceholder() {
        if let placeholder = placeholder where text.isEmpty {
            placeholderLabel.text = placeholder
            placeholderLabel.hidden = false
            placeholderLabel.font = font
            placeholderLabel.textColor = Color.grayLighter
        } else {
            placeholderLabel.text = ""
            placeholderLabel.hidden = true
        }
    }
    
    var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override func resignFirstResponder() -> Bool {
        if trim == true, let text = text where !text.isEmpty {
            self.text = text.trim
        }
        
        return super.resignFirstResponder()
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