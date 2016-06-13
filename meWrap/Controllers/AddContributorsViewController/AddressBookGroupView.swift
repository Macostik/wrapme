//
//  AddressBookGroupView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class AddressBookGroupView: EntryStreamReusableView<ArrangedAddressBookGroup> {
    
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

class AddressBookPhoneNumberCell: EntryStreamReusableView<AddressBookPhoneNumber> {
    
    private let selectionView = UIButton(type: .Custom)
    private let typeLabel = Label(preset: .Small, textColor: Color.grayLight)
    private let phoneLabel = Label(preset: .Small, textColor: Color.grayLight)
    let statusButton = specify(Button(type: .Custom)) {
        $0.titleLabel?.font = UIFont.systemFontOfSize(11)
        $0.cornerRadius = 5
        $0.setBorder(color: Color.greenOnline)
        $0.userInteractionEnabled = false
        $0.setTitleColor(Color.greenOnline, forState: .Normal)
        $0.clipsToBounds = true
        $0.insets = CGSize(width: 10, height: 0)
    }
    
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
        statusButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        statusButton.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        selectionView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        selectionView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        addSubview(selectionView)
        addSubview(statusButton)
        
        typeLabel.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.leading.centerY.equalTo(self)
        }
        
        phoneLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeLabel.snp_trailing).offset(10)
            make.centerY.equalTo(self)
            make.trailing.lessThanOrEqualTo(statusButton.snp_leading).offset(-10)
            make.trailing.lessThanOrEqualTo(selectionView.snp_leading).offset(-10)
        }
        
        selectionView.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self).inset(8)
            make.centerY.equalTo(self)
        }
        
        statusButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self).inset(11)
            make.centerY.equalTo(self)
        }
    }
    
    var state: AddressBookPhoneNumberState = .Default {
        didSet {
            switch state {
            case .Default:
                selectionView.hidden = false
                selectionView.selected = false
                statusButton.hidden = true
                statusButton.setTitle("", forState: .Normal)
            case .Selected:
                selectionView.hidden = false
                selectionView.selected = true
                statusButton.hidden = true
                statusButton.setTitle("", forState: .Normal)
            case .Added:
                selectionView.hidden = true
                statusButton.hidden = false
                statusButton.setTitle("already_in".ls, forState: .Normal)
            }
        }
    }
    
    override func setup(phoneNumber: AddressBookPhoneNumber) {
        typeLabel.text = "\(phoneNumber.label ?? ""):"
        phoneLabel.text = phoneNumber.phone
    }
}
