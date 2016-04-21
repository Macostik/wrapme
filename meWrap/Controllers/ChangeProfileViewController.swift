//
//  ChangeProfileViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 25/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

final class DeviceCell: StreamReusableView {
    
    private let name = Label(preset: .Normal, weight: .Bold, textColor: Color.grayDark)
    private let phone = Label(preset: .Small, weight: .Bold, textColor: Color.grayDark)
    private let deleteButton = Button()
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        addSubview(name)
        addSubview(phone)
        addSubview(deleteButton)
        deleteButton.titleLabel?.font = Font.Small + .Regular
        deleteButton.setTitle("delete_device".ls, forState: .Normal)
        deleteButton.setTitleColor(Color.orange, forState: .Normal)
        deleteButton.addTarget(self, action: #selector(self.deleteDevice(_:)), forControlEvents: .TouchUpInside)
        name.snp_makeConstraints { (make) in
            make.leading.equalTo(self).inset(20)
            make.bottom.equalTo(self.snp_centerY).inset(-2)
        }
        phone.snp_makeConstraints { (make) in
            make.leading.equalTo(self).inset(20)
            make.trailing.equalTo(deleteButton.snp_leading).inset(20)
            make.top.equalTo(self.snp_centerY).inset(2)
        }
        deleteButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.trailing.equalTo(self).inset(20)
        }
    }
    
    var deleteDevice: (Device -> ())?
    
    @objc private func deleteDevice(sender: AnyObject) {
        guard let device = entry as? Device else { return }
        deleteDevice?(device)
    }
    
    override func setup(entry: AnyObject?) {
        guard let device = entry as? Device else { return }
        if device.phone?.isEmpty == false {
            phone.text = device.phone
            phone.hidden = false
            name.snp_remakeConstraints { (make) in
                make.leading.equalTo(self).inset(20)
                make.bottom.equalTo(self.snp_centerY).inset(-2)
            }
        } else {
            phone.text = nil
            phone.hidden = true
            name.snp_remakeConstraints { (make) in
                make.leading.equalTo(self).inset(20)
                make.centerY.equalTo(self)
            }
        }
        
        if device.current {
            name.text = "\(device.name ?? "unnamed".ls) (\("current".ls))"
            name.font = Font.Normal + .Bold
            phone.font = Font.Small + .Bold
            deleteButton.hidden = true
        } else {
            name.text = device.name ?? "unnamed".ls
            name.font = Font.Normal + .Regular
            phone.font = Font.Small + .Regular
            deleteButton.hidden = false
        }
    }
}

private func sortDevices<T: SequenceType where T.Generator.Element: Device>(devices: T) -> [Device] {
    return devices.sort {
        if $0.current {
            return true
        }
        if $1.current {
            return false
        }
        return $0.name < $1.name
    }
}

final class ChangeProfileViewController: BaseViewController, EditSessionDelegate, UITextFieldDelegate, CaptureAvatarViewControllerDelegate, EntryNotifying, FontPresetting {
    
    private let streamView = StreamView()
    
    private lazy var dataSource: StreamDataSource<[Device]> = StreamDataSource(streamView: self.streamView)
    
    private let cancelButton = Button()
    private let doneButton = Button()
    private let resendButton = Button()
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    private let emailConfirmationView = ExpandableView()
    private let emailTextField = TextField()
    private let nameTextField = TextField()
    private let verificationEmailTextView = TextView()
    let headerView = UIView()
    let bottomView = ExpandableView()
    
    private var editSession: ProfileEditSession! {
        didSet {
            editSession.delegate = self
        }
    }
    
    class func verificationSuggestion() -> NSAttributedString? {
        if let email = Authorization.current.unconfirmed_email {
            return verificationSuggestion(email)
        }
        return nil
    }
    
    class func verificationSuggestion(email: String) -> NSAttributedString {
        let emailVerificationString = NSMutableAttributedString(string: String(format: "formatted_verification_email_text".ls, email))
        let fullRange = NSMakeRange(0, emailVerificationString.length)
        let emailString = emailVerificationString.string as NSString
        let bitRange = emailString.rangeOfString(email)
        emailVerificationString.addAttribute(NSFontAttributeName, value: UIFont.lightFontXSmall(), range:fullRange)
        emailVerificationString.addAttribute(NSFontAttributeName, value: UIFont.fontXSmall(), range:bitRange)
        return emailVerificationString
    }
    
    override func loadView() {
        super.loadView()
        
        let navigationBar = UIView()
        navigationBar.backgroundColor = Color.orange
        self.navigationBar = view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        navigationBar.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        let title = Label(preset: .Large, weight: .Bold, textColor: UIColor.whiteColor())
        title.text = "edit_profile".ls
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        
        streamView.delaysContentTouches = false
        streamView.alwaysBounceVertical = true
        view.addSubview(streamView)
        view.addSubview(bottomView)
        streamView.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(bottomView.snp_top)
            make.top.equalTo(navigationBar.snp_bottom)
        }
        
        self.keyboardBottomGuideView = bottomView
        bottomView.snp_makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(view)
        }
        
        func setupButton(button: Button, font: Font = .Large, weight: Font.Weight = .Bold, title: String, action: Selector) {
            button.backgroundColor = Color.orange
            button.normalColor = Color.orange
            button.highlightedColor = Color.orangeDark
            button.titleLabel?.font = font + weight
            button.preset = font.rawValue
            button.setTitle(title, forState: .Normal)
            button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            button.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        }
        
        setupButton(cancelButton, title: "cancel".ls, action: #selector(self.cancel(_:)))
        setupButton(doneButton, title: "done".ls, action: #selector(self.done(_:)))
        
        bottomView.addSubview(cancelButton)
        bottomView.addSubview(doneButton)
        bottomView.makeExpandable { (expandingConstraint) in
            cancelButton.snp_makeConstraints { (make) in
                make.leading.top.equalTo(bottomView)
                expandingConstraint = make.bottom.equalTo(bottomView).constraint
                make.width.equalTo(doneButton)
                make.trailing.equalTo(doneButton.snp_leading)
                make.height.equalTo(44)
            }
        }
        
        doneButton.snp_makeConstraints { (make) in
            make.trailing.top.equalTo(bottomView)
            make.height.equalTo(44)
        }
        
        streamView.addSubview(headerView)
        headerView.snp_makeConstraints { (make) in
            make.centerX.equalTo(streamView)
            make.width.equalTo(streamView)
            make.top.equalTo(streamView)
        }
        
        emailConfirmationView.clipsToBounds = true
        headerView.addSubview(emailConfirmationView)
        
        emailConfirmationView.snp_makeConstraints { (make) in
            make.leading.top.trailing.equalTo(headerView)
        }
        
        verificationEmailTextView.font = Font.Smaller + .Regular
        verificationEmailTextView.preset = Font.Smaller.rawValue
        verificationEmailTextView.textContainerInset = UIEdgeInsetsZero
        verificationEmailTextView.textContainer.lineFragmentPadding = 0
        verificationEmailTextView.scrollEnabled = false
        verificationEmailTextView.textColor = Color.grayDark
        emailConfirmationView.addSubview(verificationEmailTextView)
        
        let resendButton = Button()
        resendButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        resendButton.insets = CGSize(width: 6, height: 0)
        resendButton.clipsToBounds = true
        resendButton.cornerRadius = 4
        setupButton(resendButton, font: .Smaller, weight: .Regular, title: "resend".ls, action: #selector(self.resendEmailConfirmation(_:)))
        emailConfirmationView.addSubview(resendButton)
        
        emailConfirmationView.makeExpandable { (expandingConstraint) in
            verificationEmailTextView.snp_makeConstraints { (make) in
                make.leading.equalTo(emailConfirmationView).inset(20)
                make.bottom.equalTo(emailConfirmationView)
                expandingConstraint = make.top.equalTo(emailConfirmationView).inset(20).constraint
                make.trailing.equalTo(resendButton.snp_leading).offset(-20)
            }
        }
        
        resendButton.snp_makeConstraints { (make) in
            make.trailing.top.equalTo(emailConfirmationView).inset(20)
        }
        
        imageView.cornerRadius = 78
        imageView.defaultIconSize = 64
        imageView.borderColor = Color.grayLighter
        imageView.borderWidth = 2
        imageView.defaultIconText = "&"
        imageView.defaultIconColor = Color.grayLighter
        imageView.defaultBackgroundColor = UIColor.whiteColor()
        headerView.addSubview(imageView)
        imageView.snp_makeConstraints {
            $0.size.equalTo(156)
            $0.centerX.equalTo(headerView)
            $0.top.equalTo(emailConfirmationView.snp_bottom).offset(24)
        }
        
        let takeAvatarButton = Button(type: .Custom)
        takeAvatarButton.clipsToBounds = true
        takeAvatarButton.cornerRadius = imageView.cornerRadius
        takeAvatarButton.highlightedColor = UIColor(white: 0, alpha: 0.5)
        takeAvatarButton.addTarget(self, action: #selector(self.createImage(_:)), forControlEvents: .TouchUpInside)
        headerView.addSubview(takeAvatarButton)
        takeAvatarButton.snp_makeConstraints { (make) in
            make.edges.equalTo(imageView)
        }
        let cameraIcon = Button(icon: "u", size: 24, textColor: Color.orange)
        cameraIcon.clipsToBounds = true
        cameraIcon.cornerRadius = 22
        cameraIcon.setTitleColor(Color.orangeDark, forState: .Highlighted)
        cameraIcon.backgroundColor = UIColor.whiteColor()
        cameraIcon.normalColor = UIColor.whiteColor()
        cameraIcon.highlightedColor = Color.grayLightest
        cameraIcon.borderColor = Color.orange
        cameraIcon.borderWidth = 1
        cameraIcon.userInteractionEnabled = false
        headerView.addSubview(cameraIcon)
        takeAvatarButton.highlightings = [cameraIcon]
        cameraIcon.snp_makeConstraints { (make) in
            make.size.equalTo(44)
            make.bottom.equalTo(imageView.snp_bottom)
            make.trailing.equalTo(imageView.snp_trailing)
        }
        
        let nameLabel = Label(preset: .Smaller, weight: .Bold, textColor: Color.grayLighter)
        nameLabel.text = "name".ls
        nameLabel.highlightedTextColor = Color.orange
        headerView.addSubview(nameLabel)
        nameLabel.snp_makeConstraints { (make) in
            make.leading.equalTo(headerView).inset(20)
            make.top.equalTo(imageView.snp_bottom).offset(42)
        }
        
        func setupTextField(textField: TextField, keyboardType: UIKeyboardType, action: Selector, highlightLabel: UILabel?) {
            textField.font = Font.Normal + .Regular
            textField.textColor = Color.grayDark
            textField.delegate = self
            textField.rightViewMode = .WhileEditing
            textField.keyboardType = keyboardType
            textField.highlighLabel = highlightLabel
            textField.strokeColor = Color.grayLighter
            textField.highlightedStrokeColor = Color.orange
            textField.addTarget(self, action: action, forControlEvents: .EditingChanged)
        }
        
        setupTextField(nameTextField, keyboardType: .NamePhonePad, action: #selector(self.nameTextFieldChanged(_:)), highlightLabel: nameLabel)
        
        headerView.addSubview(nameTextField)
        nameTextField.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(headerView).inset(20)
            make.top.equalTo(nameLabel.snp_bottom)
            make.height.equalTo(40)
        }
        
        let emailLabel = Label(preset: .Smaller, weight: .Bold, textColor: Color.grayLighter)
        emailLabel.text = "email".ls
        emailLabel.highlightedTextColor = Color.orange
        headerView.addSubview(emailLabel)
        emailLabel.snp_makeConstraints { (make) in
            make.leading.equalTo(headerView).inset(20)
            make.top.equalTo(nameTextField.snp_bottom).offset(18)
        }
        
        setupTextField(emailTextField, keyboardType: .EmailAddress, action: #selector(self.emailTextFieldChanged(_:)), highlightLabel: emailLabel)
        
        headerView.addSubview(emailTextField)
        emailTextField.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(headerView).inset(20)
            make.top.equalTo(emailLabel.snp_bottom)
            make.height.equalTo(40)
        }
        
        let devicesLabel = Label(preset: .Smaller, weight: .Bold, textColor: Color.grayLighter)
        devicesLabel.text = "connected_devices".ls
        headerView.addSubview(devicesLabel)
        devicesLabel.snp_makeConstraints { (make) in
            make.leading.equalTo(headerView).inset(20)
            make.top.equalTo(emailTextField.snp_bottom).offset(28)
            make.bottom.equalTo(headerView).inset(10)
        }
        
        dataSource.addMetrics(specify(StreamMetrics(loader: StreamLoader<DeviceCell>()), {
            $0.size = 64
            $0.prepareAppearing = { [weak self] _, view in
                (view as? DeviceCell)?.deleteDevice = { device in
                    self?.deleteDevice(device)
                }
            }
        }))
    }
    
    private func deleteDevice(device: Device) {
        let message = String(format: "delete_device_message".ls, device.name ?? "")
        let alert = UIAlertController.alert("delete_device_title".ls, message: message)
        alert.action("cancel".ls)
        alert.action("delete".ls, handler: { [weak self] (_) in
            API.deleteDevice(device).send({ devices in
                self?.dataSource.items = sortDevices(devices)
                }, failure: { (error) in
                    error?.show()
            })
            })
        alert.show()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editSession = ProfileEditSession(user: User.currentUser!)
        setupEditableUserInterface()
        updateEmailConfirmationView()
        User.notifier().addReceiver(self)
        FontPresetter.defaultPresetter.addReceiver(self)
        dataSource.items = sortDevices(User.currentUser?.devices ?? [])
        API.devices().send({ [weak self] (devices) in
            self?.dataSource.items = sortDevices(devices)
            })
    }
    
    func updateEmailConfirmationView() {
        let unconfirmed_Email = Authorization.current.unconfirmed_email
        if let email = unconfirmed_Email where !email.isEmpty {
            verificationEmailTextView.attributedText = ChangeProfileViewController.verificationSuggestion(email)
        }
        emailConfirmationView.expanded = !(unconfirmed_Email?.isEmpty ?? true)
        headerView.layoutIfNeeded()
        dataSource.layoutOffset = headerView.height
    }
    
    func setupEditableUserInterface() {
        guard let user = User.currentUser else { return }
        nameTextField.text = user.name
        imageView.url = user.avatar?.large
        emailTextField.text = Authorization.current.priorityEmail
    }
    
    func validate( @noescape success: Block, @noescape failure: FailureBlock) {
        if !editSession.emailSession.hasValidChanges {
            failure(NSError(message: "incorrect_email".ls))
        } else if !editSession.nameSession.hasValidChanges {
            failure(NSError(message: "name_cannot_be_blank".ls))
        } else {
            success()
        }
    }
    
    func apply(success: ObjectBlock?, failure: FailureBlock) {
        let email = editSession.emailSession.changedValue
        if editSession.emailSession.hasChanges && Authorization.current.email != email {
            NSUserDefaults.standardUserDefaults().confirmationDate = nil
        }
        guard let user = User.currentUser else { return }
        API.updateUser(user, email: email.isEmpty ? nil : email).send(success, failure: failure)
    }
    
    @IBAction func done(sender: Button) {
        view.endEditing(true)
        validate({
            lock()
            sender.loading = true
            editSession.apply()
            apply({[weak self] _ in
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
    
    func didCompleteDoneAction() {
        self.editSession = ProfileEditSession(user: User.currentUser!)
        editSession(self.editSession, hasChanges: false)
    }
    
    func lock() {
        for subView in view.subviews {
            subView.userInteractionEnabled = false
        }
    }
    
    func unlock() {
        for subView in view.subviews {
            subView.userInteractionEnabled = true
        }
    }
    
    @IBAction func createImage(sender: AnyObject) {
        let cameraNavigation = CaptureViewController.captureAvatarViewController()
        cameraNavigation.captureDelegate = self
        presentViewController(cameraNavigation, animated: false, completion: nil)
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
        editSession.nameSession.changedValue = nameTextField.text ?? ""
    }
    
    @IBAction func emailTextFieldChanged(sender: UITextField) {
        editSession.emailSession.changedValue = emailTextField.text ?? ""
    }
    
    @IBAction func resendEmailConfirmation(sender: UIButton) {
        sender.userInteractionEnabled = false
        API.resendConfirmation(nil).send({ _ in
            InfoToast.show("confirmation_resend".ls)
            sender.userInteractionEnabled = true
        }) { error in
            error?.show()
            sender.userInteractionEnabled = true
        }
    }
    
    //MARK: EditSessionDelegate
    
    func editSession(session: EditSessionProtocol, hasChanges: Bool) {
        animate {
            bottomView.expanded = hasChanges
            view.layoutIfNeeded()
        }
        if let firstResponder = headerView.findFirstResponder() {
            streamView.scrollRectToVisible(streamView.convertRect(firstResponder.bounds, fromCoordinateSpace: firstResponder), animated: true)
        }
    }
    
    //MARK: CaptureAvatarViewControllerDelegate
    func captureViewControllerDidCancel(controller: CaptureAvatarViewController) {
        updateEmailConfirmationView()
        dataSource.reload()
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    func captureViewController(controller: CaptureAvatarViewController, didFinishWithAvatar avatar: MutableAsset) {
        let picture = avatar.uploadableAsset()
        imageView.url = picture.large
        editSession.avatarSession.changedValue = picture.large ?? ""
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    //MARK: EntryNotifying
    
    func notifier(notifier: OrderedNotifier, shouldNotifyBeforeReceiver receiver: AnyObject) -> Bool {
        return false
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        updateEmailConfirmationView()
        dataSource.reload()
    }
    
    //MARK: WLFontPresetterReceiver
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        verificationEmailTextView.attributedText = ChangeProfileViewController.verificationSuggestion()
    }
}