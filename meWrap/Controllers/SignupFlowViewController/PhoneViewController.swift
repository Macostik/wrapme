//
//  PhoneViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import libPhoneNumber_iOS

class PhoneTextField: TextField {
    
    var phoneNumberUtility: NBPhoneNumberUtil = NBPhoneNumberUtil()
    lazy var phoneNumberFormatter: NBAsYouTypeFormatter = NBAsYouTypeFormatter(regionCode: self.countryCode)
    
    var countryCode: String = "KR" {
        didSet {
            phoneNumberFormatter = NBAsYouTypeFormatter(regionCode: countryCode)
            numberTextDidChange()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        registerForNotifications()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func deleteBackward() {
        if text?.characters.last == " " {
            if let indexNumberWithWhiteSpace = text?.endIndex.advancedBy(-1) {
                text = text?.substringToIndex(indexNumberWithWhiteSpace)
            }
            return
        }
        super.deleteBackward()
    }
    
    private func registerForNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhoneTextField.numberTextDidChange), name: UITextFieldTextDidChangeNotification, object: self)
    }
    
    func numberTextDidChange() {
        let numbersOnly = phoneNumberUtility.normalizePhoneNumber(text)
        text = phoneNumberFormatter.inputStringAndRememberPosition(numbersOnly)
    }
}

class PhoneValidation: TextFieldValidation {
    
    override func defineCurrentStatus() -> ValidationStatus {
        var status = super.defineCurrentStatus()
        if status == .Valid {
            status = inputView.text?.characters.count > 5 ? .Valid : .Invalid
        }
        return status
    }
}

final class PhoneViewController: SignupStepViewController {
    
    @IBOutlet weak var phoneNumberTextField: PhoneTextField!
    
    @IBOutlet weak var selectCountryButton: UIButton!
    @IBOutlet weak var countryCodeLabel: UILabel!
    
    var country: Country! {
        didSet {
            Authorization.current.countryCode = country.callingCode
            selectCountryButton.setTitle(country.name, forState:.Normal)
            countryCodeLabel.text = "+\(country.callingCode ?? "")"
            phoneNumberTextField.countryCode = country.code
        }
    }
    
    @IBOutlet var validation: PhoneValidation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        country = Country.currentCountry()
        phoneNumberTextField.text = Authorization.current.phone
    }
    
    private func confirmAuthorization(authorization: Authorization, success: ObjectBlock) {
        ConfirmAuthorizationView().showInView(view, authorization: authorization, success: success) { [weak self] _ in
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
        let controller = CountriesViewController()
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
