//
//  ActivationViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class PasscodeValidation: TextFieldValidation {
    
    override func defineCurrentStatus() -> ValidationStatus {
        var status = super.defineCurrentStatus()
        if status == .Valid {
            status = inputView.text?.characters.count == limit ? .Valid : .Invalid
        }
        return status
    }
}

final class ActivationViewController: SignupStepViewController {
    
    var shouldSignIn = false
    
    @IBOutlet var activationTextField: UITextField!
    @IBOutlet weak var progressBar: ProgressBar!
    @IBOutlet var phoneNumberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        progressBar.progress = 0
        phoneNumberLabel.text = Authorization.current.fullPhoneNumber
        activationTextField.text = ""
    }
    
    private func signIn(success: ObjectBlock, failure: FailureBlock) {
        if shouldSignIn {
            Authorization.current.signIn().handleProgress(progressBar).send(success, failure: failure)
        } else {
            success(Authorization.current)
        }
    }
    
    private func activate(success: ObjectBlock, failure: FailureBlock) {
        NSUserDefaults.standardUserDefaults().confirmationDate = NSDate.now()
        if let code = self.activationTextField.text where !code.isEmpty {
            Authorization.current.activationCode = code
            Authorization.current.activation().handleProgress(progressBar).send({ [weak self] (_) -> Void in
                self?.signIn(success, failure: failure)
                }, failure: failure)
        } else {
            failure(nil);
        }
    }
    
    @IBAction func next(sender: Button) {
        sender.loading = true
        activate({ [weak self] (_) -> Void in
            sender.loading = false
            SoundPlayer.player.play(.s01)
            self?.setSuccessStatusAnimated(false)
            }) { [weak self] (error) -> Void in
                sender.loading = false
                self?.setFailureStatusAnimated(false)
        }
    }
    
    @IBAction func call(sender: UIButton) {
        sender.userInteractionEnabled = false
        APIRequest.verificationCall().send({ [weak self] (_) -> Void in
            sender.userInteractionEnabled = true
            UIAlertController.alert(String(format: "formatted_calling_now".ls, self?.phoneNumberLabel.text ?? "")).show()
            }) { (error) -> Void in
                sender.userInteractionEnabled = true
                error?.show()
        }
    }
}
