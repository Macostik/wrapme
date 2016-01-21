//
//  UploadWizardViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 26/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class UploadWizardViewController: WLBaseViewController {
    
    static var isActive = false
    
    private var wrap: Wrap?
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var laterButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet var layoutPrioritizer: LayoutPrioritizer!
    
    var editSession: EditSession?
    
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
            let wrap = Wrap.wrap()
            wrap.name = name
            wrap.notifyOnAddition()
            self.wrap = wrap
            editSession = EditSession(originalValue: wrap.name, setter: { _ , value -> Void in
                wrap.name = value as? String
            })
            Uploader.wrapUploader.upload(Uploading.uploading(wrap), success: nil, failure: { [weak self] error in
                    if let error = error where !error.isNetworkError {
                        self?.wrap = nil
                        error.show()
                        wrap.remove()
                        self?.navigationController?.popViewControllerAnimated(false)
                    }
            })
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
            if let controller = WLStillPictureViewController.stillPhotosViewController(wrap) {
                controller.createdWraps = NSMutableArray(object: wrap)
                controller.delegate = self
                presentViewController(controller, animated: true, completion: nil)
            }
        }
        
    }
    
    private func finish(isBroadcasting: Bool) {
        var controllers: [UIViewController] = []
        if let controller = navigationController?.viewControllers.first ?? storyboard?["home"] {
            controllers.append(controller)
        }
        
        if let controller = wrap?.viewController() {
            controllers.append(controller)
        }
        
        if isBroadcasting {
            if let controller = storyboard?["liveBroadcaster"] as? LiveBroadcasterViewController {
                controller.wrap = wrap
                controllers.append(controller)
            }
        }
        navigationController?.viewControllers = controllers
    }
    
    private func presentAddFriends(wrap: Wrap, isBroadcasting: Bool) {
        if let controller = storyboard?["addFriends"] as? WLAddContributorsViewController {
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
        let name = nameTextField.text
        editSession?.changedValue = name
        if  !isNewWrap {
           return true
        } else if name?.isEmpty ?? false {
            Toast.show("please_enter_title".ls)
             return false
        } else if name != wrap?.name {
                editSession?.apply()
                wrap?.update({ _ in
                    }, failure: { _ in })
        }
        return true
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

extension UploadWizardViewController: WLStillPictureViewControllerDelegate {
    
    func stillPictureViewControllerDidCancel(controller: WLStillPictureViewController) {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    func stillPictureViewController(controller: WLStillPictureViewController!, didFinishWithPictures pictures: [AnyObject]!) {
        dismissViewControllerAnimated(false, completion: nil)
        if let wrap = controller.wrap where self.wrap != wrap {
            self.wrap = wrap
        }
        guard let wrap = wrap else { return }
        SoundPlayer.player.play(.s04)
        if let pictures = pictures as? [MutableAsset] {
            wrap.uploadAssets(pictures)
        }
        let navigationController = self.navigationController
        finish(false)
        if let uploadWizardEnd = storyboard?["uploadWizardEnd"] as? UploadWizardEndViewController {
            uploadWizardEnd.friendsInvited = controller.friendsInvited
            if let wrapViewController = navigationController?.viewControllers.last {
                 wrapViewController.addContainedViewController(uploadWizardEnd, animated: false)
            }
        }
    }
}

class UploadWizardEndViewController: WLBaseViewController {
    
    var friendsInvited = false
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if friendsInvited {
            descriptionLabel.text = "your_friends_are_receiving_invite".ls
        } else {
            descriptionLabel.text = "wrap_is_better_with_friends".ls
        }
    }
    
    @IBAction func close(sender: UIButton?) {
       removeFromContainerAnimated(false)
    }
    
    @IBAction func panHanle(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translationInView(view).y
        let percentCompleted = abs(translation/view.height)
        switch gesture.state {
        case .Changed:
            contentView.transform = CGAffineTransformMakeTranslation(0, translation)
        case .Ended, .Cancelled:
            if  (percentCompleted > 0.25 || abs(gesture.velocityInView(view).y) > 1000) {
                let endPoint = view.height
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.contentView.transform = CGAffineTransformMakeTranslation(0, translation <= 0 ? -endPoint : endPoint)
                    }, completion: { (finished) -> Void in
                        self.close(nil)
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.contentView.transform = CGAffineTransformIdentity
                })
            }
        default:break
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       let touch = touches.first
        if let point = touch?.locationInView(view) {
            if (!contentView.frame.contains(point)) {
                close(nil)
            }
        }
    }
}
