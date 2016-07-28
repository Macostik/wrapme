//
//  ConfirmView.swift
//  meWrap
//
//  Created by Yura Granchenko on 02/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class ConfirmView: UIView {
    
    internal let contentView = UIView()
    
    internal let cancelButton = Button(preset: .Large, weight: .Regular, textColor: Color.orange)
    internal let doneButton = Button(preset: .Large, weight: .Regular, textColor: Color.orange)
    internal let bottomView = UIView()
    
    internal var doneBlock: Block?
    internal var cancelBlock: Block?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0, alpha: 0.75)
        contentView.cornerRadius = 5
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor.whiteColor()
        add(contentView) { (make) in
            make.center.equalTo(self)
            make.size.lessThanOrEqualTo(self).offset(-24)
        }
        bottomView.backgroundColor = Color.grayLighter.colorWithAlphaComponent(0.5)
        cancelButton.highlightedColor = Color.grayLighter.colorWithAlphaComponent(0.5)
        doneButton.highlightedColor = Color.grayLighter.colorWithAlphaComponent(0.5)
        cancelButton.backgroundColor = UIColor.whiteColor()
        doneButton.backgroundColor = UIColor.whiteColor()
        cancelButton.addTarget(self, touchUpInside: #selector(self.cancel(_:)))
        doneButton.addTarget(self, touchUpInside: #selector(self.done(_:)))
        contentView.add(bottomView) { (make) in
            make.leading.bottom.trailing.equalTo(contentView)
        }
        bottomView.add(cancelButton) { (make) in
            make.leading.bottom.equalTo(bottomView)
            make.top.equalTo(bottomView).inset(1)
            make.height.equalTo(44)
        }
        bottomView.add(doneButton) { (make) in
            make.trailing.bottom.equalTo(bottomView)
            make.top.equalTo(bottomView).inset(1)
            make.leading.equalTo(cancelButton.snp_trailing).inset(-1)
            make.width.equalTo(cancelButton.snp_width)
            make.height.equalTo(44)
        }
        layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func layout() {}
    
    func showInView(view: UIView, success: Block?, cancel: Block?) {
        self.doneBlock = success
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
    
    internal func cancel(sender: AnyObject) {
        cancelBlock?()
        hide()
    }
    
    internal func done(sender: AnyObject) {
        doneBlock?()
        hide()
    }
}

final class ConfirmAuthorizationView: ConfirmView {
    
    private let emailLabel = Label(preset: .Large, weight: .Light, textColor: Color.gray)
    private let phoneLabel = Label(preset: .Large, weight: .Light, textColor: Color.gray)
    
    override func layout() {
        cancelButton.setTitle("edit".ls, forState: .Normal)
        doneButton.setTitle("ok".ls, forState: .Normal)
        let confirmLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.gray)
        confirmLabel.text = "confirm_your_details".ls
        confirmLabel.textAlignment = .Center
        contentView.add(confirmLabel) { (make) in
            make.top.equalTo(contentView).inset(20)
            make.centerX.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(20)
        }
        emailLabel.textAlignment = .Center
        contentView.add(emailLabel) { (make) in
            make.top.equalTo(confirmLabel.snp_bottom).inset(-20)
            make.centerX.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(20)
        }
        phoneLabel.textAlignment = .Center
        contentView.add(phoneLabel) { (make) in
            make.top.equalTo(emailLabel.snp_bottom)
            make.centerX.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(20)
        }
        let correctLabel = Label(preset: .Normal, weight: .Light, textColor: Color.gray)
        correctLabel.text = "is_it_correct".ls
        correctLabel.textAlignment = .Center
        contentView.add(correctLabel) { (make) in
            make.top.equalTo(phoneLabel.snp_bottom).inset(-20)
            make.centerX.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(20)
            make.bottom.equalTo(bottomView.snp_top).inset(-20)
        }
    }
    
    func showInView(view: UIView, authorization: Authorization, success: Authorization -> (), cancel: Block?) {
        emailLabel.text = authorization.email ?? ""
        phoneLabel.text = authorization.fullPhoneNumber
        showInView(view, success: {
            success(authorization)
            }, cancel: cancel)
    }
}

final class ConfirmInvitationView: ConfirmView, UITextViewDelegate {
    
    private let contentTextView = TextView()
    
    override func layout() {
        cancelButton.setTitle("cancel".ls, forState: .Normal)
        doneButton.setTitle("ok".ls, forState: .Normal)
        let inviteLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.gray)
        inviteLabel.text = "invite_to_meWrap".ls
        inviteLabel.textAlignment = .Center
        inviteLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Vertical)
        contentView.add(inviteLabel) { (make) in
            make.top.equalTo(contentView).inset(20)
            make.centerX.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(20)
        }
        let sendLabel = Label(preset: .Normal, weight: .Light, textColor: Color.gray)
        sendLabel.text = "send_message_to_friends_body".ls
        sendLabel.textAlignment = .Center
        sendLabel.numberOfLines = 0
        sendLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Vertical)
        contentView.add(sendLabel) { (make) in
            make.top.equalTo(inviteLabel.snp_bottom).inset(-20)
            make.centerX.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(20)
        }
        
        contentTextView.textColor = Color.gray
        contentTextView.font = Font.Small + .Regular
        contentTextView.makePresetable(.Small)
        contentTextView.backgroundColor = Color.grayLightest
        contentTextView.clipsToBounds = true
        contentTextView.cornerRadius = 5
        contentView.add(contentTextView) { (make) in
            make.top.equalTo(sendLabel.snp_bottom).inset(-20)
            make.height.equalTo(100)
            make.leading.trailing.equalTo(contentView).inset(20)
            make.bottom.equalTo(bottomView.snp_top).inset(-20)
        }
    }
    
    func showInView(view: UIView, content: String, success: String -> Void, cancel: Block?) {
        
        Keyboard.keyboard.handle(self, block: { [unowned self] (keyboard, willShow) in
            keyboard.performAnimation { () in
                if willShow {
                    self.contentView.snp_remakeConstraints(closure: { (make) in
                        make.centerX.equalTo(self)
                        make.centerY.equalTo(self).inset(-keyboard.height/2)
                        make.width.lessThanOrEqualTo(self).offset(-24)
                        make.height.lessThanOrEqualTo(self).offset(-(24 + keyboard.height))
                    })
                    self.contentView.layoutIfNeeded()
                } else {
                    self.contentView.snp_remakeConstraints(closure: { (make) in
                        make.center.equalTo(self)
                        make.size.lessThanOrEqualTo(self).offset(-24)
                    })
                    self.contentView.layoutIfNeeded()
                }
            }
            })
        contentTextView.text = content
        contentTextView.delegate = self
        self.showInView(view, success: { [weak self] _ in
            if let text = self?.contentTextView.text {
                success(text)
            }
            }, cancel: cancel)
    }
    
    //MARK: UITextViewDelegate
    
    let WLMessageLimit = 160
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if let string: NSString = textView.text {
            let resultString = string.stringByReplacingCharactersInRange(range, withString: text)
            return resultString.characters.count <= WLMessageLimit
        }
        return false
    }
}
