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
    optional func composeBar(composeBar: ComposeBar, didChangeHeight oldHeight: CGFloat)
    optional func composeBarDidChangeText(composeBar: ComposeBar)
    optional func composeBarDidBeginEditing(composeBar: ComposeBar)
    optional func composeBarDidEndEditing(composeBar: ComposeBar)
}

final class ComposeBar: UIControl, UITextViewDelegate {
    
    @IBOutlet weak var delegate: ComposeBarDelegate?
    @IBOutlet weak var textView: TextView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingPrioritizer: LayoutPrioritizer!
    @IBOutlet weak var emojiButton: UIButton!
    
    @IBInspectable var maxLines: CGFloat = 0
    
    var charactersLimit = Constants.composeBarDefaultCharactersLimit
    
    private lazy var emojiView: EmojiView = EmojiView.emojiView(self)
    
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
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UIResponder.becomeFirstResponder)))
        textView.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UIResponder.becomeFirstResponder)))
    }
    
    final func updateHeight() {
        if let textView = textView {
            guard let font = textView.font else { return }
            let lineHeight = floorf(Float(font.lineHeight))
            let spacing = textView.y * 2
            var height = textView.sizeThatFits(CGSizeMake(textView.width, CGFloat(MAXFLOAT))).height + spacing
            let maxLines = self.maxLines > 0 ? self.maxLines : 5
            height = smoothstep(36, maxLines * CGFloat(lineHeight) + spacing, height)
            if Int(heightConstraint.constant) != Int(height) {
                let oldHeight = heightConstraint.constant
                heightConstraint.constant = height
                layoutIfNeeded()
                delegate?.composeBar?(self, didChangeHeight: oldHeight)
            }
        }
    }
    
    func setDoneButtonHidden(hidden: Bool) {
        trailingPrioritizer.defaultState = hidden
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return subviews.contains({ $0.pointInside($0.convertPoint(point, fromView: self), withEvent: event) })
    }
    
    //MARK: Actions
    
    @IBAction func done(sender: AnyObject) {
        if let text = self.text?.trim where !text.isEmpty {
            delegate?.composeBar?(self, didFinishWithText: text)
        }
    }
    
    var isEmojiKeyboardActive = false {
        willSet {
            if newValue != isEmojiKeyboardActive {
                emojiButton.selected = newValue
                textView.inputView = nil
                if newValue {
                    textView.inputView = emojiView
                }
                if !isFirstResponder() {
                    becomeFirstResponder()
                }
                textView.reloadInputViews()
            }
        }
    }
    
    @IBAction func selectEmoji(sender: UIButton) {
        isEmojiKeyboardActive = !isEmojiKeyboardActive
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
        var resultString: NSString = textView.text
        resultString = resultString.stringByReplacingCharactersInRange(range, withString: text)
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