//
//  EmailViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class EmailValidation: TextFieldValidation {
    
    override func defineCurrentStatus() -> ValidationStatus {
        var status = super.defineCurrentStatus()
        if status == .Valid {
            status = inputView.text?.isValidEmail ?? false ? .Valid : .Invalid
        }
        return status
    }
}

final class EmailViewController: SignupStepViewController {
    
    @IBOutlet weak var emailField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.text = Authorization.current.email
    }
    
    @IBAction func next(sender: Button) {
        sender.loading = true
        view.endEditing(true)
        API.whois(emailField.text!).send({ [weak self] whoIs -> Void in
            sender.loading = false
            if whoIs.found && whoIs.requiresApproving {
                self?.setStatus(whoIs.confirmed ? .LinkDevice : .UnconfirmedEmail, animated: false)
            } else {
                self?.setStatus(.Verification, animated: false)
            }
            }) { (error) -> Void in
                sender.loading = false
                error?.show()
        }
    }
    
    @IBAction func useTestAccount(sender: AnyObject) {
        TestUserPicker.showInView(UIWindow.mainWindow) { (authorization) -> Void in
            ConfirmAuthorizationView().showInView(UIWindow.mainWindow, authorization: authorization, success: { _ in
                authorization.signIn().send({ _ in
                    UINavigationController.main.viewControllers = [HomeViewController()]
                    }, failure: { $0?.show() })
                }, cancel: nil)
        }
    }
}

final class ConfirmEmailViewController: SignupStepViewController {
    
    @IBOutlet weak var resendEmailButton: UIButton!
    @IBOutlet weak var useAnotherEmailButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailLabel?.text = "\(Authorization.current.email ?? "") is not confirmed yet"
        useAnotherEmailButton.setBorder(color: Color.orange)
        User.notifier().addReceiver(self)
    }
    
    @IBAction func resend(sender: AnyObject) {
        API.resendConfirmation(Authorization.current.email).send({ (_) -> Void in
            UIAlertController.alert("sending_confirming_email".ls).show()
            }) { [weak self] (error) -> Void in
                if let error = error {
                    if error.isResponseError(.EmailAlreadyConfirmed) {
                        self?.setSuccessStatusAnimated(false)
                        Toast.show("Your email is already confirmed.")
                    } else {
                        error.show()
                    }
                }
        }
    }
}

extension ConfirmEmailViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if (Authorization.current.unconfirmed_email?.isEmpty ?? true) && isTopViewController {
            setSuccessStatusAnimated(false)
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry == User.currentUser
    }
}
