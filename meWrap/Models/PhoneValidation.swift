//
//  PhoneValidation.swift
//  
//
//  Created by Yura Granchenko on 04/02/16.
//
//

import Foundation
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
        if status == .ValidStatus {
            status = textField.text?.characters.count > 5 ? .ValidStatus : .InvalidStatus
        }
        return status
    }
    
    //MARK: UITextFieldDelegate 
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        textField.text = string.characters.count > 0 ? formatter?.inputDigit(string) : formatter?.removeLastDigit()
        return false
    }
    
    
}
