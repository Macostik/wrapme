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
    func recordCell(cell: AddressBookRecordCell, didSelectPhoneNumber person: AddressBookPhoneNumber)
    func recordCell(cell: AddressBookRecordCell, phoneNumberState phoneNumber: AddressBookPhoneNumber) -> AddressBookPhoneNumberState
    func recordCellDidToggle(cell: AddressBookRecordCell)
}

class AddressBookRecordCell: StreamReusableView {
    
    @IBOutlet weak var delegate: AddressBookRecordCellDelegate!
    
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarView: ImageView!
    @IBOutlet weak var openView: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var pandingLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var statusPrioritizer: LayoutPrioritizer!
    var dataSource: StreamDataSource?
    
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
    
    var opened: Bool = false {
        willSet {
            UIView.beginAnimations(nil, context: nil)
            openView.selected = newValue
            UIView.commitAnimations()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let streamView = streamView {
            dataSource = StreamDataSource(streamView: streamView)
            dataSource?.addMetrics(StreamMetrics(identifier: "AddressBookPhoneNumberCell", initializer: { metrics in
                metrics.size = 50.0
                metrics.selectable = true
                metrics.finalizeAppearing = { [weak self] item, view in
                    let cell = view as? AddressBookPhoneNumberCell
                    let phoneNumber = item.entry as? AddressBookPhoneNumber
                    if let weakSelf = self, let phoneNumber = phoneNumber {
                        cell?.checked = weakSelf.delegate.recordCell(weakSelf, phoneNumberState: phoneNumber) != .Default
                    }
                }
                metrics.selection = { [weak self] item, phoneNumber in
                    if let weakSelf = self, let phoneNumber = phoneNumber as? AddressBookPhoneNumber {
                        weakSelf.delegate.recordCell(weakSelf, didSelectPhoneNumber: phoneNumber)
                    }
                }
            }))
        }
    }
    
    override func setup(entry: AnyObject) {
        guard let record = entry as? AddressBookRecord else { return }
        guard let phoneNumber = record.phoneNumbers.last else { return }
        let url = phoneNumber.avatar?.small
        if url?.isEmpty ?? true && phoneNumber.user != nil {
            avatarView.defaultBackgroundColor = Color.orange
        } else {
            avatarView.defaultBackgroundColor = Color.grayLighter
        }
        avatarView.url = url
        

        if streamView != nil {
            layoutIfNeeded()
            dataSource?.items = record.phoneNumbers
            statusLabel.text = "invite_me_to_meWrap".ls
        } else {
            let user = phoneNumber.user
            phoneLabel.text = record.phoneStrings
            pandingLabel.text = user?.isInvited ?? false ? "sign_up_pending".ls : ""
            if phoneNumber.activated {
                statusLabel.text = "signup_status".ls
            } else if (user != nil) {
                statusLabel.text = String(format:"invite_status".ls, user?.invitedAt.stringWithDateStyle(.ShortStyle) ?? "")
            } else {
                statusLabel.text = "invite_me_to_meWrap".ls
            }
            state = delegate?.recordCell(self, phoneNumberState: phoneNumber) ?? .Default
            let notInvited = !(user != nil && state == .Added)
            statusButton?.hidden = notInvited
            statusPrioritizer?.defaultState = notInvited
        }
    }
    
    //MARK: Actions
    
     @IBAction func _select(sender: AnyObject) {
        let record = entry as? AddressBookRecord
        if let person = record?.phoneNumbers.last {
            delegate?.recordCell(self, didSelectPhoneNumber: person)
        }
    }
    
    @IBAction func open(sender: AnyObject) {
        opened = !opened
        delegate?.recordCellDidToggle(self)
    }
}