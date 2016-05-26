//
//  AddressBookRecordCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 05/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

enum AddressBookPhoneNumberState {
    case Default, Selected, Added
}

protocol AddressBookRecordCellDelegate: class {
    func recordCell(cell: AddressBookRecordCell, didSelectPhoneNumber person: AddressBookPhoneNumber)
    func recordCell(cell: AddressBookRecordCell, phoneNumberState phoneNumber: AddressBookPhoneNumber) -> AddressBookPhoneNumberState
    func recordCellDidToggle(cell: MultipleAddressBookRecordCell)
}

class AddressBookRecordCell: EntryStreamReusableView<AddressBookRecord> {
    
    weak var delegate: AddressBookRecordCellDelegate?
    
    internal let nameLabel = Label(preset: .Normal, textColor: Color.grayDark)
    
    internal func selectPhoneNumber(phoneNumber: AddressBookPhoneNumber?) {
        if let phoneNumber = phoneNumber {
            delegate?.recordCell(self, didSelectPhoneNumber: phoneNumber)
        }
    }
    
    override func setup(record: AddressBookRecord) {
        guard let phoneNumber = record.phoneNumbers.last else { return }
        setup(record, phoneNumber: phoneNumber)
    }
    
    internal func setup(record: AddressBookRecord, phoneNumber: AddressBookPhoneNumber) { }
}

final class SingleAddressBookRecordCell: AddressBookRecordCell {
    
    private let infoLabel = Label(preset: .Small, textColor: Color.grayLight)
    private let selectButton = specify(Button(type: .Custom)) {
        $0.titleLabel?.font = UIFont.icons(26)
        $0.setTitle("G", forState: .Normal)
        $0.setTitle("H", forState: .Selected)
        $0.setTitleColor(Color.grayLighter, forState: .Normal)
        $0.setTitleColor(Color.orange, forState: .Selected)
    }
    private let statusButton = specify(Button(type: .Custom)) {
        $0.titleLabel?.font = UIFont.systemFontOfSize(11)
        $0.cornerRadius = 5
        $0.borderColor = Color.greenOnline
        $0.borderWidth = 1
        $0.userInteractionEnabled = false
        $0.setTitleColor(Color.greenOnline, forState: .Normal)
        $0.clipsToBounds = true
        $0.insets = CGSize(width: 10, height: 0)
    }
    private let avatarView = specify(StatusUserAvatarView(cornerRadius: 24)) {
        $0.startReceivingStatusUpdates()
        $0.placeholder.font = UIFont.icons(24)
    }
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        infoLabel.numberOfLines = 0
        selectButton.addTarget(self, action: #selector(SingleAddressBookRecordCell._select(_:)), forControlEvents: .TouchUpInside)
        infoLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        addSubview(avatarView)
        addSubview(nameLabel)
        addSubview(infoLabel)
        addSubview(selectButton)
        addSubview(statusButton)
        avatarView.snp_makeConstraints { (make) -> Void in
            make.leading.top.equalTo(self).inset(12)
            make.size.equalTo(48)
        }
        nameLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(statusButton.snp_leading)
            make.trailing.lessThanOrEqualTo(selectButton.snp_leading)
        }
        infoLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(nameLabel.snp_bottom)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(statusButton.snp_leading)
            make.trailing.lessThanOrEqualTo(selectButton.snp_leading)
        }
        selectButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self).inset(8)
            make.centerY.equalTo(self)
            make.width.equalTo(30)
        }
        statusButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self).inset(11)
            make.centerY.equalTo(self)
        }
    }
    
    weak var wrap: Wrap?
    
    override func setup(record: AddressBookRecord, phoneNumber: AddressBookPhoneNumber) {
        nameLabel.text = phoneNumber.name
        if let user = phoneNumber.user {
            avatarView.wrap = wrap
            avatarView.user = user
        } else {
            avatarView.user = nil
            avatarView.url = phoneNumber.avatar?.small
        }
        infoLabel.text = record.infoString
        let state = delegate?.recordCell(self, phoneNumberState: phoneNumber) ?? .Default
        selectButton.hidden = state == .Added
        selectButton.selected = state == .Selected
        statusButton.hidden = !selectButton.hidden
        statusButton.setTitle(statusButton.hidden ? "" : "already_in".ls, forState: .Normal)
    }
    
    //MARK: Actions
    
    @IBAction func _select(sender: AnyObject) {
        selectPhoneNumber(entry?.phoneNumbers.last)
    }
}

final class MultipleAddressBookRecordCell: AddressBookRecordCell {
    
    private let streamView = StreamView()
    private var dataSource: StreamDataSource<[AddressBookPhoneNumber]>!
    private let avatarView = ImageView(backgroundColor: UIColor.whiteColor(), placeholder: ImageView.Placeholder.gray)
    private let openView = specify(UIButton(type: .Custom)) {
        $0.titleLabel?.font = UIFont.icons(18.0)
        $0.setTitle("y", forState: .Normal)
        $0.setTitle("z", forState: .Selected)
        $0.setTitleColor(Color.grayLighter, forState: .Normal)
        $0.contentHorizontalAlignment = .Right
        $0.titleEdgeInsets.right = 13
    }
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        dataSource = StreamDataSource(streamView: streamView)
        dataSource.addMetrics(StreamMetrics<AddressBookPhoneNumberCell>().change({ [weak self] metrics in
            metrics.size = 50.0
            metrics.selectable = true
            metrics.finalizeAppearing = { item, view in
                let phoneNumber = item.entry as? AddressBookPhoneNumber
                if let weakSelf = self, let phoneNumber = phoneNumber {
                    view.checked = weakSelf.delegate?.recordCell(weakSelf, phoneNumberState: phoneNumber) != .Default
                }
            }
            metrics.selection = { view in
                self?.selectPhoneNumber(view.entry)
            }
            }))
        openView.addTarget(self, action: #selector(MultipleAddressBookRecordCell.open(_:)), forControlEvents: .TouchUpInside)
        avatarView.cornerRadius = 24
        let infoLabel = Label(preset: .Small, textColor: Color.grayLight)
        infoLabel.text = "invite_me_to_meWrap".ls
        addSubview(streamView)
        addSubview(openView)
        addSubview(avatarView)
        addSubview(nameLabel)
        addSubview(infoLabel)
        streamView.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.bottom.equalTo(self)
            make.top.equalTo(avatarView.snp_bottom)
        }
        openView.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.top.equalTo(self)
            make.bottom.equalTo(avatarView)
        }
        avatarView.snp_makeConstraints { (make) -> Void in
            make.leading.top.equalTo(self).inset(12)
            make.size.equalTo(48)
        }
        nameLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(self).inset(44)
        }
        infoLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(nameLabel.snp_bottom)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(self).inset(44)
        }
    }
    
    override func setup(record: AddressBookRecord, phoneNumber: AddressBookPhoneNumber) {
        nameLabel.text = phoneNumber.name
        avatarView.url = phoneNumber.avatar?.small
        layoutIfNeeded()
        dataSource.items = record.phoneNumbers
    }
    
    var opened: Bool = false {
        willSet {
            UIView.beginAnimations(nil, context: nil)
            openView.selected = newValue
            UIView.commitAnimations()
        }
    }
    
    @IBAction func open(sender: AnyObject) {
        opened = !opened
        delegate?.recordCellDidToggle(self)
    }
}