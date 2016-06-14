//
//  AddressBookGroupView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

final class AddressBookGroupView: EntryStreamReusableView<ArrangedAddressBookGroup> {
    
    private let titleLabel = Label(preset: .Small, textColor: Color.orangeDark)
    
    override func setup(group: ArrangedAddressBookGroup) {
        titleLabel.text = group.title
    }
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        backgroundColor = Color.orangeLight
        titleLabel.textAlignment = .Left
        addSubview(titleLabel)
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.equalTo(self).inset(5)
            make.centerY.equalTo(self)
        }
    }
}

final class AddressBookPhoneNumberCell: EntryStreamReusableView<AddressBookPhoneNumber> {
    
    private let selectionView = UIButton(type: .Custom)
    private let typeLabel = Label(preset: .Small, textColor: Color.grayLight)
    private let phoneLabel = Label(preset: .Small, textColor: Color.grayLight)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
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
        selectionView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        selectionView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        addSubview(selectionView)
        
        typeLabel.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.leading.centerY.equalTo(self)
        }
        
        phoneLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeLabel.snp_trailing).offset(10)
            make.centerY.equalTo(self)
            make.trailing.lessThanOrEqualTo(selectionView.snp_leading).offset(-10)
        }
        
        selectionView.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self).inset(8)
            make.centerY.equalTo(self)
        }
    }
    
    var checked: Bool = false {
        didSet {
            selectionView.selected = checked
        }
    }
    
    override func setup(phoneNumber: AddressBookPhoneNumber) {
        typeLabel.text = "\(phoneNumber.label ?? ""):"
        phoneLabel.text = phoneNumber.phone
    }
}
