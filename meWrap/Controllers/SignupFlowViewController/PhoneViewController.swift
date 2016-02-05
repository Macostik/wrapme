//
//  PhoneViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import libPhoneNumber_iOS

class PhoneValidation: TextFieldValidation {
    
    private var formatter: NBAsYouTypeFormatter?
    
    var country: Country? {
        willSet {
            formatter = NBAsYouTypeFormatter(regionCode: country?.code)
            if let text = inputView.text where !text.isEmpty {
                inputView.text = formatter?.inputString(text.clearPhoneNumber())
                validate()
            }
        }
    }
    
    override func defineCurrentStatus(textField: UITextField) -> ValidationStatus {
        var status = super.defineCurrentStatus(textField)
        if status == .Valid {
            status = textField.text?.characters.count > 5 ? .Valid : .Invalid
        }
        return status
    }
    
    //MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        textField.text = string.characters.count > 0 ? formatter?.inputDigit(string) : formatter?.removeLastDigit()
        return false
    }
}

final class PhoneViewController: SignupStepViewController {
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    @IBOutlet weak var selectCountryButton: UIButton!
    @IBOutlet weak var countryCodeLabel: UILabel!
    
    var country: Country! {
        didSet {
            Authorization.current.countryCode = country.callingCode
            selectCountryButton.setTitle(country.name, forState:.Normal)
            countryCodeLabel.text = "+\(country.callingCode)"
            validation.country = country
        }
    }
    
    @IBOutlet var validation: PhoneValidation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        country = Country.currentCountry()
        phoneNumberTextField.text = Authorization.current.phone
    }
    
    private func confirmAuthorization(authorization: Authorization, success: ObjectBlock) {
        ConfirmView.showInView(view, authorization: authorization, success: success) { [weak self] _ in
            self?.setStatus(.Cancel, animated: false)
        }
    }
    
    @IBAction func next(sender: Button) {
        view.endEditing(true)
        let authorization = Authorization.current
        authorization.countryCode = country.callingCode
        authorization.phone = phoneNumberTextField.text?.clearPhoneNumber()
        authorization.formattedPhone = phoneNumberTextField.text
        confirmAuthorization(authorization) { [weak self] _ in
            sender.loading = true
            authorization.signUp().send({ _ in
                self?.setStatus(.Success, animated: false)
                sender.loading = false
                }, failure: { (error) -> Void in
                    error?.show()
                    sender.loading = false
            })
        }
    }
    
    @IBAction func selectCountry(sender: AnyObject) {
        let controller = Storyboard.Countries.instantiate()
        controller.selectedCountry = self.country
        controller.selectionBlock = { [weak self] country in
            self?.country = country
            self?.navigationController?.popViewControllerAnimated(false)
        }
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @IBAction func phoneChanged(sender: UITextField) {
        let authorization = Authorization.current
        authorization.phone = sender.text?.clearPhoneNumber()
        authorization.formattedPhone = sender.text
    }
}
