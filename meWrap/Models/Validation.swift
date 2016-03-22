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
    
    @IBOutlet weak var inputView: UITextField!
    
    @IBOutlet weak var statusView: UIView! {
        didSet {
            updateStatusView(status)
        }
    }
    
    var status: ValidationStatus = .Undefined {
        didSet {
            updateStatusView(status)
        }
    }

    func updateStatusView(status: ValidationStatus) {
        statusView?.userInteractionEnabled = status == .Valid
        statusView?.alpha = status == .Valid ? 1.0 : 0.5
    }
    
    func validate() -> ValidationStatus {
        let status = defineCurrentStatus()
        self.status = status
        return status
    }
    
    func defineCurrentStatus() -> ValidationStatus {
        return .Valid
    }
}

class TextFieldValidation: Validation {
    
    override weak var inputView: UITextField! {
        didSet {
            inputView.addTarget(self, action: #selector(TextFieldValidation.textDidChange), forControlEvents: .EditingChanged)
        }
    }
    
    @IBInspectable var limit: Int = 0
    
    override func defineCurrentStatus() -> ValidationStatus {
        return inputView.text?.isEmpty ?? true ? .Invalid : .Valid
    }
    
    //MARK: ValidationDelegate
    
    func textDidChange() {
        if let text = inputView.text {
            if limit > 0 && text.characters.count > limit {
                let index = text.startIndex.advancedBy(limit)
                inputView.text = text.substringToIndex(index)
            }
        }
        validate()
    }
}
