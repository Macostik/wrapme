//
//  ValidationGroup.swift
//  meWrap
//
//  Created by Yura Granchenko on 04/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class ValidationGroup: Validation, ValidationDelegate {
    
    @IBOutlet var validations: [Validation]! {
        willSet {
            newValue.forEach({$0.delegate = self})
        }
    }
    
    func defineCurrentStatus(inptutView: UIView) ->  ValidationStatus {
        for validation in validations {
            if validation.status != .ValidStatus {
                reason = validation.reason
                return validation.status
            }
        }
        return .ValidStatus
    }
    
    //MARK: ValidationDelegate 
    
    func validationStatusChanged(validation: Validation) {
        validate()
    }
}



