//
//  EditProfileViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class EditProfileViewController: SignupStepViewController {
    
    @IBOutlet var profileImageView: ImageView!
    @IBOutlet var createImageButton: UIButton!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    @IBOutlet weak var continueButton: Button!
    
    private var editSession: ProfileEditSession!
    private weak var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = User.currentUser
        editSession = ProfileEditSession(user: user)
        nameTextField.text = user.name
        profileImageView.url = user.avatar?.large
        continueButton.active = false
    }
    
    private func updateIfNeeded(completion: Void -> Void) {
        if editSession.hasChanges {
            view.userInteractionEnabled = false
            continueButton.loading = true
            editSession.apply()
            APIRequest.updateUser(user, email: nil).send({ [weak self] _ in
                self?.continueButton.loading = false
                self?.view.userInteractionEnabled = true
                completion()
                }, failure: { [weak self] (error) -> Void in
                    self?.editSession.reset()
                    self?.continueButton.loading = false
                    self?.view.userInteractionEnabled = true
                    error?.show()
                })
        } else {
            completion()
        }
    }
    
    @IBAction func goToMainScreen(sender: AnyObject) {
        updateIfNeeded({ [weak self] _ in
            self?.setSuccessStatusAnimated(false)
            })
    }
    
    @IBAction func createImage(sender: AnyObject) {
        let cameraNavigation = CaptureViewController.captureAvatarViewController()
        cameraNavigation.captureDelegate = self
        presentViewController(cameraNavigation, animated: false, completion: nil)
    }
}

extension EditProfileViewController: CaptureAvatarViewControllerDelegate {
    
    func captureViewControllerDidCancel(controller: CaptureAvatarViewController) {
        controller.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func captureViewController(controller: CaptureAvatarViewController, didFinishWithAvatar avatar: MutableAsset) {
        profileImageView.url = avatar.large
        editSession.avatarSession.changedValue = avatar.large ?? ""
        addPhotoLabel.hidden = true
        controller.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
}

extension EditProfileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        editSession.nameSession.changedValue = nameTextField.text ?? ""
    }
    
    @IBAction func nameChanged(sender: UITextField) {
        if let text = sender.text where text.characters.count > Constants.profileNameLimit {
            sender.text = text.substringToIndex(text.startIndex.advancedBy(Constants.profileNameLimit))
        }
        editSession.nameSession.changedValue = sender.text ?? ""
        continueButton.active = editSession.nameSession.hasValidChanges
    }
}
