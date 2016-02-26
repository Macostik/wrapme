//
//  ComposeBar.swift
//  meWrap
//
//  Created by Yura Granchenko on 29/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

@objc protocol ComposeBarDelegate {
    optional func composeBar(composeBar: ComposeBar, didFinishWithText text: String)
    optional func composeBarDidChangeHeight(composeBar: ComposeBar)
    optional func composeBarDidChangeText(composeBar: ComposeBar)
    optional func composeBarDidBeginEditing(composeBar: ComposeBar)
    optional func composeBarDidEndEditing(composeBar: ComposeBar)
    optional func composeBarCharactersLimit(composeBar: ComposeBar) -> Int
    optional func composeBarDidShouldResignOnFinish(composeBar: ComposeBar) -> Bool
}

class ComposeBar: UIControl, UITextViewDelegate {
    
    @IBOutlet weak var delegate: ComposeBarDelegate?
    @IBOutlet weak var textView: TextView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingPrioritizer: LayoutPrioritizer!
    
    @IBInspectable var maxLines: CGFloat = 0
    
    lazy var emojiView: EmojiView = {
        let emojiView = EmojiView.emojiViewWithTextView(self.textView)
        emojiView.backgroundColor = self.backgroundColor
        return emojiView
    }()
    
    var text: String? {
        set {
            textView.text = newValue
            textView.placeholderLabel?.hidden = !(newValue?.isEmpty ?? true) || textView.selectedRange.location != 0
            updateHeight()
            setDoneButtonHidden(newValue?.trim.isEmpty ?? true)
        }
        get {
            return textView.text
        }
    }
    
    deinit {
        textView?.delegate = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = UIEdgeInsetsZero
        textView.textContainerInset = textView.contentInset
        setDoneButtonHidden(true)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "becomeFirstResponder"))
        textView.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "becomeFirstResponder"))
    }
    
    final func updateHeight() {
        if let textView = textView {
            guard let font = textView.font else { return }
            let lineHeight = floorf(Float(font.lineHeight))
            let spacing = textView.y * 2
            var height = textView.sizeThatFits(CGSizeMake(textView.width, CGFloat(MAXFLOAT))).height + spacing
            let maxLines = self.maxLines > 0 ? self.maxLines : 5
            height = smoothstep(36, maxLines * CGFloat(lineHeight) + spacing, height)
            if heightConstraint.constant != height {
                heightConstraint.constant = height
                layoutIfNeeded()
                delegate?.composeBarDidChangeHeight?(self)
            }
        }
    }
    
    func finish() {
        if (delegate?.composeBarDidShouldResignOnFinish?(self)) == true {
            textView.resignFirstResponder()
        }

        if case let text = self.text, let trimText = text?.trim where !trimText.isEmpty {
            delegate?.composeBar?(self, didFinishWithText: trimText)
        }
        Dispatch.mainQueue.async {[weak self] _ in
            self?.text = nil
        }
    }
    
    final func setDoneButtonHidden(hidden: Bool) {
        trailingPrioritizer.defaultState = hidden
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subView in subviews {
            let inside = subView.pointInside(subView.convertPoint(point, fromView: self), withEvent: event)
            if inside == true {
                return true
            }
        }
        return false
    }
    
    //MARK: Actions
    
    @IBAction func done(sender: AnyObject) {
        finish()
    }
    
    @IBAction func selectEmoji(sender: UIButton) {
        sender.selected = !sender.selected
        textView.inputView = nil
        if sender.selected {
            textView.inputView = emojiView
        }
        if isFirstResponder() {
            becomeFirstResponder()
        }
        textView.reloadInputViews()
    }
    
    //MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        delegate?.composeBarDidChangeText?(self)
        updateHeight()
        setDoneButtonHidden(textView.text.trim.isEmpty)
        sendActionsForControlEvents(.EditingChanged)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        setDoneButtonHidden(textView.text.trim.isEmpty)
        delegate?.composeBarDidBeginEditing?(self)
        sendActionsForControlEvents(.EditingDidBegin)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        setDoneButtonHidden(textView.text.trim.isEmpty)
        delegate?.composeBarDidEndEditing?(self)
        sendActionsForControlEvents(.EditingDidEnd)
        updateHeight()
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        var charactersLimit: Int = 0;
        if let limit = delegate?.composeBarCharactersLimit?(self) where height > 44.0 {
            charactersLimit = limit
        } else {
            charactersLimit = Int(Constants.composeBarDefaultCharactersLimit)
        }
        let resultString: NSString = textView.text
        resultString.stringByReplacingCharactersInRange(range, withString: text)
        return resultString.length <= charactersLimit
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        textView.scrollRangeToVisible(textView.selectedRange)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var offset = scrollView.contentOffset
        let maxOffsetY = scrollView.maximumContentOffset.y
        if offset.y > maxOffsetY {
            offset.y = maxOffsetY
            scrollView.contentOffset = offset
        }
    }
    
    //MARK: UIResponder
    
    override func canBecomeFirstResponder() -> Bool {
        return textView.canBecomeFirstResponder()
    }
    
    override func canResignFirstResponder() -> Bool {
        return textView.canResignFirstResponder()
    }
    
    override func isFirstResponder() -> Bool {
        return textView.isFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
}