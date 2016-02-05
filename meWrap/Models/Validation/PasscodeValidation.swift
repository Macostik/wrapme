//
//  PasscodeValidation.swift
//  meWrap
//
//  Created by Yura Granchenko on 04/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class PasscodeValidation: TextFieldValidation {
    
    override func defineCurrentStatus(textField: UITextField) -> ValidationStatus {
        var status = super.defineCurrentStatus(textField)
        if status == .ValidStatus {
            status = textField.text?.characters.count == limit ? .ValidStatus : .InvalidStatus
        }
        return status
    }
}


