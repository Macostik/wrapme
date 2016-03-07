//
//  AddressBookRecordCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 05/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

@objc enum AddressBookPhoneNumberState: Int {
    case Default, Selected, Added
}

@objc protocol AddressBookRecordCellDelegate {
    func recordCell(cell: StreamReusableView, didSelectPhoneNumber person: AddressBookPhoneNumber)
    func recordCell(cell: StreamReusableView, phoneNumberState phoneNumber: AddressBookPhoneNumber) -> AddressBookPhoneNumberState
    func recordCellDidToggle(cell: MultipleAddressBookRecordCell)
}

class AddressBookRecordCell: StreamReusableView {
    
    @IBOutlet weak var delegate: AddressBookRecordCellDelegate!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarView: ImageView!
    
    internal func selectPhoneNumber(phoneNumber: AddressBookPhoneNumber?) {
        if let phoneNumber = phoneNumber {
            delegate.recordCell(self, didSelectPhoneNumber: phoneNumber)
        }
    }
}

final class SingleAddressBookRecordCell: AddressBookRecordCell {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet var statusPrioritizer: LayoutPrioritizer!
    
    var state: AddressBookPhoneNumberState = .Default {
        willSet {
            if newValue == .Added {
                selectButton.enabled = false
            } else {
                selectButton.enabled = true
                selectButton.selected = newValue == .Selected
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        statusButton?.borderColor = Color.greenOnline
        statusButton?.setTitleColor(Color.greenOnline, forState: .Normal)
    }
    
    override func setup(entry: AnyObject?) {
        guard let record = entry as? AddressBookRecord else { return }
        guard let phoneNumber = record.phoneNumbers.last else { return }
        nameLabel.text = phoneNumber.name
        let url = phoneNumber.avatar?.small
        if url?.isEmpty ?? true && phoneNumber.user != nil {
            avatarView.defaultBackgroundColor = Color.orange
        } else {
            avatarView.defaultBackgroundColor = Color.grayLighter
        }
        avatarView.url = url
        
        let user = phoneNumber.user
        infoLabel.text = record.infoString
        state = delegate?.recordCell(self, phoneNumberState: phoneNumber) ?? .Default
        let notInvited = !(user != nil && state == .Added)
        statusButton.hidden = notInvited
        statusPrioritizer.defaultState = notInvited
    }
    
    //MARK: Actions
    
    @IBAction func _select(sender: AnyObject) {
        selectPhoneNumber((entry as? AddressBookRecord)?.phoneNumbers.last)
    }
}

final class MultipleAddressBookRecordCell: AddressBookRecordCell {
    
    @IBOutlet weak var streamView: StreamView!
    private var dataSource: StreamDataSource!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarView.defaultBackgroundColor = Color.grayLighter
        dataSource = StreamDataSource(streamView: streamView)
        dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<AddressBookPhoneNumberCell>()).change({ [weak self] metrics in
            metrics.size = 50.0
            metrics.selectable = true
            metrics.finalizeAppearing = { item, view in
                let cell = view as? AddressBookPhoneNumberCell
                let phoneNumber = item.entry as? AddressBookPhoneNumber
                if let weakSelf = self, let phoneNumber = phoneNumber {
                    cell?.checked = weakSelf.delegate.recordCell(weakSelf, phoneNumberState: phoneNumber) != .Default
                }
            }
            metrics.selection = { item, phoneNumber in
                self?.selectPhoneNumber(phoneNumber as? AddressBookPhoneNumber)
            }
            }))
    }
    
    override func setup(entry: AnyObject?) {
        guard let record = entry as? AddressBookRecord else { return }
        guard let phoneNumber = record.phoneNumbers.last else { return }
        nameLabel.text = phoneNumber.name
        avatarView.url = phoneNumber.avatar?.small
        layoutIfNeeded()
        dataSource.items = record.phoneNumbers
    }
    
    var opened: Bool = false {
        willSet {
            UIView.beginAnimations(nil, context: nil)
            openView?.selected = newValue
            UIView.commitAnimations()
        }
    }
    
    @IBOutlet weak var openView: UIButton?
    
    @IBAction func open(sender: AnyObject) {
        opened = !opened
        delegate?.recordCellDidToggle(self)
    }
}