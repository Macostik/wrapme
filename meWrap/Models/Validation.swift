//
//  Validation.swift
//  meWrap
//
//  Created by Yura Granchenko on 03/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

enum ValidationStatus {
    case Undefined, Invalid, Valid
}

class Validation: NSObject, UITextFieldDelegate {
    
    @IBOutlet weak var inputView: UITextField! {
        willSet {
            newValue.delegate = self
            newValue.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
        }
    }
    
    @IBOutlet weak var statusView: UIView! {
        didSet {
            updateStatusView(status)
        }
    }
    
    var status: ValidationStatus = .Undefined {
        willSet {
            updateStatusView(newValue)
        }
    }

    func updateStatusView(status: ValidationStatus) {
        statusView?.userInteractionEnabled = status == .Valid
        statusView?.alpha = status == .Valid ? 1.0 : 0.5
    }
    
    func validate() -> ValidationStatus {
        let status = defineCurrentStatus(inputView)
        self.status = status
        return status
    }
    
    func defineCurrentStatus(textField: UITextField) -> ValidationStatus {
        return .Valid
    }
}

class TextFieldValidation: Validation {
    
    @IBInspectable var limit: Int = 0
    
    override func defineCurrentStatus(textField: UITextField) -> ValidationStatus {
        return textField.text?.isEmpty ?? false ? .Invalid : .Valid
    }
    
    //MARK: ValidationDelegate
    
    func textFieldDidChange(textField: UITextField) {
        if let text = textField.text {
            if limit > 0 && text.characters.count > limit {
                let index = text.startIndex.advancedBy(limit)
                textField.text = text.substringToIndex(index)
            }
        }
        validate()
    }
}
