//
//  UploadWizardViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 26/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class UploadWizardViewController: BaseViewController {
    
    static var isActive = false
    
    private var wrap: Wrap?
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var laterButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet var layoutPrioritizer: LayoutPrioritizer!
    
    private func defaultWrap() -> Wrap? {
        guard isValidateWrap() else { return nil }
        if let wrap = wrap {
            return wrap
        } else {
            var text: String?
            if isNewWrap {
                text = nameTextField.text
            } else {
                text = String(format:"first_wrap".ls, User.currentUser?.name ?? "")
            }
            guard let name = text where !name.isEmpty else { return nil }
            let wrap = insertWrap()
            wrap.name = name
            self.wrap = wrap
            Uploader.wrapUploader.upload(Uploading.uploading(wrap), success: nil, failure: { [weak self] error in
                if let error = error where !error.isNetworkError {
                    self?.wrap = nil
                    error.show()
                    wrap.remove()
                    self?.navigationController?.popViewControllerAnimated(false)
                }
                })
            wrap.notifyOnAddition()
            return wrap
        }
    }
    
    deinit {
        UploadWizardViewController.isActive = false
    }
    
    var isNewWrap = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UploadWizardViewController.isActive = true
        descriptionLabel.hidden = isNewWrap
        nameTextField.hidden = !isNewWrap
        laterButton.hidden = isNewWrap
        backButton.hidden = !isNewWrap
        layoutPrioritizer.defaultState = !isNewWrap
    }
    
    @IBAction func presentCamera(sender: AnyObject) {
        if let wrap = defaultWrap() {
            let controller = CaptureViewController.captureMediaViewController(wrap)
            controller.createdWraps = [wrap]
            controller.captureDelegate = self
            presentViewController(controller, animated: false, completion: nil)
        }
        
    }
    
    private func finish(isBroadcasting: Bool) {
        var controllers: [UIViewController] = []
        if let controller = navigationController?.viewControllers.first ?? storyboard?["home"] {
            controllers.append(controller)
        }
        
        if let controller = wrap?.createViewController() {
            controllers.append(controller)
        }
        
        if isBroadcasting {
            let controller = LiveBroadcasterViewController()
            controller.wrap = wrap
            controllers.append(controller)
        }
        navigationController?.viewControllers = controllers
    }
    
    private func presentAddFriends(wrap: Wrap, isBroadcasting: Bool) {
        Storyboard.AddFriends.instantiate { (controller) -> Void in
            controller.wrap = wrap
            controller.isBroadcasting = isBroadcasting
            controller.isWrapCreation = true
            navigationController?.pushViewController(controller, animated: false)
            controller.completionHandler = { [weak self] _ in
                self?.finish(isBroadcasting)
            }
        }
    }
    
    @IBAction func presentBroadcastLive(sender: AnyObject) {
        if let wrap = defaultWrap() {
            presentAddFriends(wrap, isBroadcasting: true)
        }
    }
    
    @IBAction func cancel(sender: AnyObject?) {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func isValidateWrap () -> Bool {
        let name = nameTextField.text? .trim
        if !isNewWrap {
            return true
        } else if name?.isEmpty ?? false {
            Toast.show("please_enter_title".ls)
            return false
        } else if name != wrap?.name {
            let currentName = wrap?.name
            wrap?.name = name
            wrap?.update({ _ in
                }, failure: { [weak self] error in
                    self?.wrap?.name = currentName
            })
        }
        return true
    }
    
    override func keyboardAdjustmentConstant(adjustment: KeyboardAdjustment, keyboard: Keyboard) -> CGFloat {
        return adjustment.defaultConstant - keyboard.height/2
    }
}

extension UploadWizardViewController: UITextFieldDelegate {
    
    @IBAction func textFieldDidChange(textField: UITextField) {
        if let text = textField.text where text.characters.count > Constants.profileNameLimit {
            textField.text = text.substringToIndex(text.startIndex.advancedBy(Constants.profileNameLimit))
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension UploadWizardViewController: CaptureCandyViewControllerDelegate {
    
    func captureViewControllerDidCancel(controller: CaptureCandyViewController) {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    func captureViewController(controller: CaptureCandyViewController, didFinishWithAssets assets: [MutableAsset]) {
        dismissViewControllerAnimated(false, completion: nil)
        if let wrap = controller.wrap where self.wrap != wrap {
            self.wrap = wrap
        }
        wrap?.uploadAssets(assets)
        let navigationController = self.navigationController
        finish(false)
        Storyboard.UploadWizardEnd.instantiate { (uploadWizardEnd) -> Void in
            uploadWizardEnd.wrap = wrap
            uploadWizardEnd.friendsInvited = controller.friendsInvited
            if let wrapViewController = navigationController?.viewControllers.last {
                wrapViewController.addContainedViewController(uploadWizardEnd, animated: false)
            }
        }
    }
}

class UploadWizardEndViewController: BaseViewController {
    
    var friendsInvited = false
    
    weak var wrap: Wrap?
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    
    private lazy var slideTransition: SlideTransition = SlideTransition(view: self.contentView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slideTransition.didFinish = { [weak self] _ in
            self?.close()
        }
        if friendsInvited {
            descriptionLabel.text = String(format: "wrap_shared_message".ls, wrap?.name ?? "")
        } else {
            let message = NSAttributedString(string: String(format: "share_wrap_message".ls, wrap?.name ?? ""), attributes: [NSFontAttributeName:descriptionLabel.font,NSForegroundColorAttributeName:Color.grayDark])
            descriptionLabel.attributedText = message
            descriptionLabel.userInteractionEnabled = true
        }
    }
    
    func close() {
        removeFromContainerAnimated(false)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first
        if let point = touch?.locationInView(view) {
            if (!contentView.frame.contains(point)) {
                close()
            }
        }
    }
}
