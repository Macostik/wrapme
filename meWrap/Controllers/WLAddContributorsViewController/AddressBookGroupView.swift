//
//  AddressBookGroupView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class AddressBookGroupView: StreamReusableView {

    @IBOutlet weak var titleLabel: UILabel!
    
    var group: ArrangedAddressBookGroup? {
        didSet {
            titleLabel.text = group?.title
        }
    }
}

class AddressBookPhoneNumberCell: StreamReusableView {
    
    @IBOutlet weak var selectionView: UIButton!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    var checked = false {
        didSet {
            UIView.beginAnimations(nil, context:nil)
            selectionView.selected = checked
            UIView.commitAnimations()
        }
    }
    
    override func setup(entry: AnyObject) {
        if let phoneNumber = entry as? AddressBookPhoneNumber {
            typeLabel.text = "\(phoneNumber.label ?? ""):"
            phoneLabel.text = phoneNumber.phone
        }
    }
}
