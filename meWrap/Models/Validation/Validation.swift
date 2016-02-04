ra//
//  Validation.swift
//  meWrap
//
//  Created by Yura Granchenko on 03/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

enum ValidationStatus {
    case UndefinedStatus
    case InvalidStatus
    case ValidStatus
}

@objc protocol ValidationDelegate {
    func validationStatusChanged(validation: Validation)
}

class Validation: NSObject, UITextFieldDelegate {
    
    var reason: String?
    weak var delegate: ValidationDelegate?
    @IBOutlet weak var inputView: UITextField! {
        willSet {
            newValue.delegate = self
            newValue.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
        }
    }
    @IBOutlet weak var statusView: UIView! {
        willSet {
            updateStatusView(self.status ?? .UndefinedStatus)
        }
    }
    var status: ValidationStatus = .UndefinedStatus {
        willSet {
            updateStatusView(newValue ?? .UndefinedStatus)
        }
    }
    
    override init() {
        super.init()
        prepare()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        prepare()
    }
    
    func prepare() {}
    
    func statusChanged(status: ValidationStatus) {
        updateStatusView(status)
        delegate?.validationStatusChanged(self)
    }
    
    func updateStatusView(status: ValidationStatus) {
        if let statusView = statusView {
            statusView.userInteractionEnabled = status == .ValidStatus
            statusView.alpha = status == .ValidStatus ? 1.0 : 0.5
        }
    }
    
    func validate() -> ValidationStatus {
        status = .ValidStatus
        return status
    }
}