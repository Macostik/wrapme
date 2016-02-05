//
//  EmailValidation.swift
//  meWrap
//
//  Created by Yura Granchenko on 04/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class EmailValidation: TextFieldValidation {
    
    override func defineCurrentStatus(textField: UITextField) -> ValidationStatus {
        var status = super.defineCurrentStatus(textField)
        if status == .ValidStatus {
            status = textField.text?.isValidEmail ?? false ? .ValidStatus : .InvalidStatus
        }
        return status
    }
}

