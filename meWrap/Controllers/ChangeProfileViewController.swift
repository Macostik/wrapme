//
//  ChangeProfileViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 25/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class ChangeProfileViewController: WLBaseViewController, EditSessionDelegate, UITextFieldDelegate, WLStillPictureViewControllerDelegate, EntryNotifying, FontPresetting {
    
    @IBOutlet weak var cancelButton: Button!
    @IBOutlet weak var doneButton: Button!
    @IBOutlet weak var resendButton: Button!
    @IBOutlet weak var imageView: ImageView!
    @IBOutlet weak var emailConfirmationView: UIView!
    @IBOutlet weak var imagePlaceholderView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var verificationEmailTextView: WLTextView!
    
    
    private var editSession: ProfileEditSession! {
        didSet {
            editSession.delegate = self
        }
    }
    
    class func verificationSuggestion() -> NSAttributedString? {
        if let email = Authorization.currentAuthorization.unconfirmed_email {
            return verificationSuggestion(email)
        }
        return nil
    }
    
    class func verificationSuggestion(email: String) -> NSAttributedString {
        let emailVerificationString = NSMutableAttributedString(string: String(format: "formatted_verification_email_text".ls, email))
        let fullRange = NSMakeRange(0, emailVerificationString.length)
        let emailString = emailVerificationString.string as NSString
        let bitRange = emailString.rangeOfString(email)
        if let lightFontXSmall = UIFont.lightFontXSmall(), let fontXSmall = UIFont.fontXSmall() {
            emailVerificationString.addAttribute(NSFontAttributeName, value: lightFontXSmall, range:fullRange)
            emailVerificationString.addAttribute(NSFontAttributeName, value: fontXSmall, range:bitRange)
        }
        return emailVerificationString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editSession = ProfileEditSession(user: User.currentUser!)
        verificationEmailTextView.textContainerInset = UIEdgeInsetsZero
        verificationEmailTextView.textContainer.lineFragmentPadding = 0;
        setupEditableUserInterface()
        updateEmailConfirmationView()
        User.notifier().addReceiver(self)
        FontPresetter.defaultPresetter.addReceiver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let rect = emailConfirmationView.convertRect(CGRectInset(resendButton.frame, -5, -5), toView: verificationEmailTextView)
        let resendButtonExclusionPath = UIBezierPath(rect: rect)
        let avatarRect = view.convertRect(imagePlaceholderView.frame, toView: verificationEmailTextView)
        let avatarPath = UIBezierPath(ovalInRect: avatarRect)
        verificationEmailTextView.textContainer.exclusionPaths = [resendButtonExclusionPath, avatarPath]
    }
    
    final func updateEmailConfirmationView() {
        let unconfirmed_Email = Authorization.currentAuthorization.unconfirmed_email
        if let email = unconfirmed_Email where !email.isEmpty {
            verificationEmailTextView.attributedText = ChangeProfileViewController.verificationSuggestion(email)
        }
        emailConfirmationView.hidden = unconfirmed_Email?.isEmpty ?? false
    }
    
    final func setupEditableUserInterface() {
        guard let user = User.currentUser else { return }
        nameTextField.text = user.name
        imageView.url = user.avatar?.large
        emailTextField.text = Authorization.currentAuthorization.priorityEmail
    }
    
    final func validate(success: ObjectBlock?, failure: FailureBlock?) {
        if !editSession.emailSession.hasValidChanges {
            failure?(NSError(message: "incorrect_email".ls))
        } else if !editSession.nameSession.hasValidChanges {
            failure?(NSError(message: "name_cannot_be_blank".ls))
        } else {
            success?(nil)
        }
    }
    
    final func apply(success: ObjectBlock?, failure: FailureBlock) {
        if let email = editSession.emailSession.changedValue as? String {
            if case let emailSession = editSession.emailSession where emailSession.hasChanges && Authorization.currentAuthorization.email != email {
                NSUserDefaults.standardUserDefaults().confirmationDate = nil
            }
            guard let user = User.currentUser else { return }
            APIRequest.updateUser(user, email: email).send(success, failure: failure)
        }
    }
    
    @IBAction func done(sender: Button) {
        view.endEditing(true)
            validate({[weak self] _ in
                self?.lock()
                sender.loading = true
                self?.editSession.apply()
                self?.apply({[weak self] _ in
                    self?.didCompleteDoneAction()
                    sender.loading = false
                    self?.unlock()
                    }, failure: {[weak self] (error) -> Void in
                        self?.editSession.reset()
                        error?.show()
                        sender.loading = false
                        self?.unlock()
                    })
                }, failure: { (error) in
                    error?.show()
            })
        
        
    }
    
    @IBAction func cancel(sender: AnyObject) {
        editSession.clean()
        setupEditableUserInterface()
        view.endEditing(true)
    }
    
    final func didCompleteDoneAction() {
        self.editSession = ProfileEditSession(user: User.currentUser!)
        editSession(self.editSession, hasChanges: false)
    }
    
    final func lock() {
        for subView in view.subviews {
            subView.userInteractionEnabled = false
        }
    }
    
    final func unlock() {
        for subView in view.subviews {
            subView.userInteractionEnabled = true
        }
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let text: NSString = textField.text {
            let resultString = text.stringByReplacingCharactersInRange(range, withString: string)
            return resultString.characters.count <= Constants.profileNameLimit
        }
        return false
    }
    
    @IBAction func nameTextFieldChanged(sender: UITextField) {
        editSession.nameSession.changedValue = nameTextField.text
    }
    
    @IBAction func emailTextFieldChanged(sender: UITextField) {
        editSession.emailSession.changedValue = emailTextField.text
    }
    
    @IBAction func resendEmailConfirmation(sender: UIButton) {
        sender.userInteractionEnabled = false
        APIRequest.resendConfirmation(nil) .send({ _ in
            Toast.show("confirmation_resend".ls)
            sender.userInteractionEnabled = true
            }) { _ in
                sender.userInteractionEnabled = true
        }
    }
    
    //MARK: EditSessionDelegate
    
    final func editSession(session: EditSession, hasChanges: Bool) {
        doneButton.hidden =     !hasChanges
        cancelButton.hidden =   !hasChanges
        doneButton.addAnimation(CATransition.transition(kCATransitionFade))
        cancelButton.addAnimation(CATransition.transition(kCATransitionFade))
    }
    
    //MARK: WLStillPictureViewControllerDelegate
    
    func stillPictureViewControllerDidCancel(controller: WLStillPictureViewController!) {
        updateEmailConfirmationView()
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    func stillPictureViewController(controller: WLStillPictureViewController!, didFinishWithPictures pictures: [AnyObject]!) {
        let asset = pictures.last as? MutableAsset
        let picture = asset?.uploadablePicture(false)
        imageView.url = picture?.large
        editSession.avatarSession.changedValue = picture?.large
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    //MARK: EntryNotifying
    
    func notifier(notifier: OrderedNotifier, shouldNotifyBeforeReceiver receiver: AnyObject) -> Bool {
        return false
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        updateEmailConfirmationView()
    }
    
    //MARK: WLFontPresetterReceiver
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        verificationEmailTextView.attributedText = ChangeProfileViewController.verificationSuggestion()
    }
    
}