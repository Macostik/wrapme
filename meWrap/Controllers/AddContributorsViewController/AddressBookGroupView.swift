//
//  AddressBookGroupView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class AddressBookGroupView: StreamReusableView {

    private var titleLabel = Label(preset: .Small, textColor: Color.orangeDark)
    
    var group: ArrangedAddressBookGroup? {
        didSet {
            titleLabel.text = group?.title
        }
    }
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        backgroundColor = Color.orangeLight
        titleLabel.textAlignment = .Left
        addSubview(titleLabel)
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.equalTo(self).inset(5)
            make.centerY.equalTo(self)
        }
    }
}

class AddressBookPhoneNumberCell: StreamReusableView {
    
    private var selectionView = UIButton(type: .Custom)
    private var typeLabel = Label(preset: .Small, textColor: Color.grayLight)
    private var phoneLabel = Label(preset: .Small, textColor: Color.grayLight)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        typeLabel.textAlignment = .Right
        addSubview(typeLabel)
        phoneLabel.textAlignment = .Left
        addSubview(phoneLabel)
        selectionView.userInteractionEnabled = false
        selectionView.titleLabel?.font = UIFont.icons(26)
        selectionView.setTitle("G", forState: .Normal)
        selectionView.setTitle("H", forState: .Selected)
        selectionView.setTitleColor(Color.grayLight, forState: .Normal)
        selectionView.setTitleColor(Color.orange, forState: .Selected)
        addSubview(selectionView)
        
        typeLabel.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.leading.centerY.equalTo(self)
        }
        
        phoneLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeLabel.snp_trailing).offset(10)
            make.trailing.equalTo(selectionView.snp_leading).offset(2)
            make.centerY.equalTo(self)
        }
        
        selectionView.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self).inset(8)
            make.centerY.equalTo(self)
        }
    }
    
    var checked = false {
        didSet {
            UIView.beginAnimations(nil, context:nil)
            selectionView.selected = checked
            UIView.commitAnimations()
        }
    }
    
    override func setup(entry: AnyObject?) {
        if let phoneNumber = entry as? AddressBookPhoneNumber {
            typeLabel.text = "\(phoneNumber.label ?? ""):"
            phoneLabel.text = phoneNumber.phone
        }
    }
}
