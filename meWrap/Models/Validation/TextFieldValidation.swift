//
//  TextFieldValidation.swift
//  meWrap
//
//  Created by Yura Granchenko on 04/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class TextFieldValidation: Validation {
    
    var limit = 0
    
    func defineCurrentStatus(textField: UITextField) -> ValidationStatus {
        return textField.text?.isEmpty ?? false ? .InvalidStatus : .ValidStatus
    }
    
    //MARK: ValidationDelegate 
    
    func textFieldDidChange(textField: UITextField) {
        if let text = textField.text {
            if limit > 0 && text.characters.count > limit {
                let index = text.startIndex.advancedBy(limit)
                textField.text = text.substringToIndex(index)
            }
        }
    }
}
