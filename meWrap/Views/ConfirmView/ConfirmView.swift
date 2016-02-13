//
//  ConfirmView.swift
//  meWrap
//
//  Created by Yura Granchenko on 02/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class ConfirmView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    
    internal var successBlock: (AnyObject? -> Void)?
    internal var cancelBlock: Block?
    
    func showInView(view: UIView, success: (AnyObject? -> Void)?, cancel: Block?) {
        self.successBlock = success
        self.cancelBlock = cancel
        frame = view.frame
        view.addSubview(self)
        backgroundColor = UIColor.clearColor()
        contentView.transform = CGAffineTransformMakeScale(0.5, 0.5)
        contentView.alpha = 0.0
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .CurveEaseIn , animations: { _ in
            self.contentView.transform = CGAffineTransformIdentity
            }, completion: nil)
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn , animations: { () -> Void in
            self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
            self.contentView.alpha = 1.0
            }, completion: nil)
        
    }
    
    func hide() {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: .CurveEaseIn , animations: { _ in
            self.contentView.transform = CGAffineTransformMakeScale(0.5, 0.5)
            self.contentView.alpha = 0.0
            self.backgroundColor = UIColor.clearColor()
            }, completion: { _ in
                self.removeFromSuperview()
        })
    }
    
    @IBAction func cancel(sender: AnyObject) {
        cancel()
    }
    
    @IBAction func confirm(sender: AnyObject) {
        confirm()
    }
    
    internal func cancel() {
        cancelBlock?()
        hide()
    }
    
    internal func confirm() {
        hide()
    }
}

final class ConfirmAuthorizationView: ConfirmView {
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    var authorization: Authorization? {
        willSet {
            emailLabel?.text = newValue?.email ?? ""
            phoneLabel?.text = newValue?.fullPhoneNumber
        }
    }
    
    class func instance() -> Self {
        return loadFromNib("ConfirmAuthorizationView")!
    }
    
    func showInView(view: UIView, authorization: Authorization?, success: ObjectBlock?, cancel: Block?) {
        self.authorization = authorization
        showInView(view, success: success, cancel: cancel)
    }
    
    override func confirm() {
        successBlock?(authorization)
        hide()
    }
}

final class ConfirmInvitationView: ConfirmView, KeyboardNotifying, UITextViewDelegate {
    
    @IBOutlet weak var titleLabel: Label!
    @IBOutlet weak var bodyLabel: Label!
    @IBOutlet weak var contentTextView: TextView!
    @IBOutlet weak var keyboardPrioritizer: NSLayoutConstraint!
    
    class func instance() -> Self {
        return loadFromNib("ConfirmInvitationView")!
    }
    
    func showInView(view: UIView, content: String, success: AnyObject? -> Void, cancel: Block?) {
        Keyboard.keyboard.addReceiver(self)
        contentTextView.text = content
        contentTextView.delegate = self
        self.showInView(view, success: success, cancel: cancel)
    }
    
    override func confirm() {
        successBlock?(contentTextView.text)
    }
    
    func keyboardWillShow(keyboard: Keyboard) {
        UIView.animateWithDuration(0.25) { _ in
            self.keyboardPrioritizer.constant -= keyboard.height/2
            self.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(keyboard: Keyboard) {
        UIView.animateWithDuration(0.25) { _ in
            self.keyboardPrioritizer.constant += keyboard.height/2
            self.layoutIfNeeded()
        }
    }
    
    //MARK: UITextViewDelegate
    
    let WLMessageLimit = 280
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if let string: NSString = textView.text {
            let resultString = string.stringByReplacingCharactersInRange(range, withString: text)
            return resultString.characters.count <= WLMessageLimit
        }
        return false
    }
}
