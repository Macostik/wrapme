//
//  ConfirmView.swift
//  meWrap
//
//  Created by Yura Granchenko on 02/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class ConfirmView: UIView {
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    
    var success: ObjectBlock?
    var cancel: Block?
    
    var authorization: Authorization? {
        willSet {
            emailLabel?.text = newValue?.email ?? ""
            phoneLabel?.text = newValue?.fullPhoneNumber
        }
    }
    
    class func showInView(view: UIView, authorization: Authorization, success: ObjectBlock?, cancel: Block?) {
        ConfirmView.loadFromNib("ConfirmView")?.showInView(view, authorization: authorization, success: success, cancel: cancel)
    }
    
    func showInView(view: UIView, authorization: Authorization?, success: ObjectBlock?, cancel: Block?) {
        frame = view.frame
        self.authorization = authorization
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
        confirmationSuccess(success, cancel: cancel)
    }
    
    func confirmationSuccess(success: ObjectBlock?, cancel: Block?) {
        self.success = success
        self.cancel = cancel
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
        cancel?()
        hide()
    }
    
    @IBAction func confirm(sender: AnyObject) {
        success?(authorization)
        hide()
    }
}

final class EditingConfirmView: ConfirmView, KeyboardNotifying, UITextViewDelegate {
    @IBOutlet weak var titleLabel: Label!
    @IBOutlet weak var bodyLabel: Label!
    @IBOutlet weak var contentTextView: TextView!
    @IBOutlet weak var keyboardPrioritizer: NSLayoutConstraint!
    
    class func showInView(view: UIView, content: String, success: ObjectBlock?, cancel: Block?) {
       EditingConfirmView.loadFromNib("EditingConfirmView")?.showInView(view, content: content, success: success, cancel: cancel)
        
    }
    
    func showInView(view: UIView, content: String, success: ObjectBlock?, cancel: Block?) {
        Keyboard.keyboard.addReceiver(self)
        contentTextView.determineHyperLink(content)
        contentTextView.delegate = self
        super.showInView(view, authorization: nil, success: success, cancel: cancel)
    }
    
    @IBAction override func confirm(sender: AnyObject) {
        success?(contentTextView.text)
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
