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
    let textView = TextView()
    let contentView = UIView()
    let emojiButton = Button(icon: "J", size: 24, textColor: Color.orange)
    let doneButton = Button(icon: ")", size: 24, textColor: Color.orange)
    
    @IBInspectable var maxLines: CGFloat = 0
    
    var charactersLimit = Constants.composeBarDefaultCharactersLimit
    
    private lazy var emojiView: EmojiView = EmojiView.emojiView(self)
    
    convenience init() {
        self.init(frame: CGRect.zero)
        layout()
    }
    
    func layout() {
        clipsToBounds = true
        textView.backgroundColor = UIColor.clearColor()
        emojiButton.setTitle("K", forState: .Selected)
        emojiButton.addTarget(self, touchUpInside: #selector(self.selectEmoji(_:)))
        add(emojiButton) { (make) in
            make.size.equalTo(44)
            make.centerY.leading.equalTo(self)
        }
        add(contentView) { (make) in
            make.leading.equalTo(emojiButton.snp_trailing)
            make.top.bottom.equalTo(self).inset(6)
            make.height.equalTo(36)
        }
        contentView.add(textView) { (make) in
            make.leading.trailing.equalTo(contentView)
            make.top.bottom.equalTo(contentView).inset(8)
        }
        textView.font = Font.Normal + .Light
        textView.textColor = UIColor.whiteColor()
        textView.preset = Font.Normal.rawValue
        textView.delegate = self
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = UIEdgeInsetsZero
        textView.textContainerInset = textView.contentInset
        doneButton.addTarget(self, touchUpInside: #selector(self.done(_:)))
        doneButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        add(doneButton) { (make) in
            make.size.equalTo(48)
            make.centerY.equalTo(self)
            make.leading.equalTo(contentView.snp_trailing)
            make.trailing.equalTo(self).inset(-48)
        }
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.becomeFirstResponder)))
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.becomeFirstResponder)))
    }
    
    var animatesDoneButton = true
    
    var text: String? {
        set {
            textView.text = newValue
            updateHeight()
            setDoneButtonHidden(newValue?.trim.isEmpty ?? true, animated: animatesDoneButton)
        }
        get {
            return textView.text
        }
    }
    
    deinit {
        textView.delegate = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layout()
    }
    
    final func updateHeight() {
        guard let font = textView.font else { return }
        let lineHeight = floorf(Float(font.lineHeight))
        let spacing = textView.y * 2
        var height = textView.sizeThatFits(CGSizeMake(textView.width, CGFloat(MAXFLOAT))).height + spacing
        let maxLines = self.maxLines > 0 ? self.maxLines : 5
        height = smoothstep(36, maxLines * CGFloat(lineHeight) + spacing, height)
        let oldHeight = contentView.height
        if Int(oldHeight) != Int(height) {
            contentView.snp_updateConstraints(closure: { (make) in
                make.height.equalTo(height)
            })
            layoutIfNeeded()
            delegate?.composeBar?(self, didChangeHeight: oldHeight)
        }
    }
    
    func setDoneButtonHidden(hidden: Bool, animated: Bool) {
        animate(animated) {
            doneButton.snp_updateConstraints { (make) in
                make.trailing.equalTo(self).inset(hidden ? -48 : 0)
            }
            doneButton.layoutIfNeeded()
        }
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
        setDoneButtonHidden(textView.text.trim.isEmpty, animated: animatesDoneButton)
        sendActionsForControlEvents(.EditingChanged)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        setDoneButtonHidden(textView.text.trim.isEmpty, animated: animatesDoneButton)
        delegate?.composeBarDidBeginEditing?(self)
        sendActionsForControlEvents(.EditingDidBegin)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        setDoneButtonHidden(textView.text.trim.isEmpty, animated: animatesDoneButton)
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