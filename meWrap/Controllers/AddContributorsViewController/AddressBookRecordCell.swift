//
//  AddressBookRecordCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 05/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

protocol AddressBookRecordCellDelegate: class {
    func recordCell(cell: AddressBookRecordCell, didSelectPhoneNumber person: AddressBookPhoneNumber)
    func recordCell(cell: AddressBookRecordCell, phoneNumberIsSelected phoneNumber: AddressBookPhoneNumber) -> Bool
    func recordCellDidToggle(cell: MultipleAddressBookRecordCell)
}

class AddressBookRecordCell: EntryStreamReusableView<ArrangedAddressBookRecord> {
    
    weak var delegate: AddressBookRecordCellDelegate?
    
    internal let nameLabel = Label(preset: .Normal, weight: .Semibold, textColor: AddContributorsViewController.darkStyle ? .whiteColor() : Color.grayDark)
    
    internal func selectPhoneNumber(phoneNumber: AddressBookPhoneNumber?) {
        if let phoneNumber = phoneNumber {
            delegate?.recordCell(self, didSelectPhoneNumber: phoneNumber)
        }
    }
    
    override func setup(record: ArrangedAddressBookRecord) {
        guard let phoneNumber = record.phoneNumbers.last else { return }
        setup(record, phoneNumber: phoneNumber)
    }
    
    internal func setup(record: ArrangedAddressBookRecord, phoneNumber: AddressBookPhoneNumber) { }
}

final class SingleAddressBookRecordCell: AddressBookRecordCell {
    
    private let infoLabel = Label(preset: .Smaller, weight: .Regular, textColor: AddContributorsViewController.darkStyle ? .whiteColor() : Color.grayLight)
    private let phoneNumbersLabel = Label(preset: .Smaller, weight: .Regular, textColor: AddContributorsViewController.darkStyle ? Color.grayLighter : Color.grayLight)
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
        $0.setBorder(color: Color.greenOnline)
        $0.userInteractionEnabled = false
        $0.setTitleColor(Color.greenOnline, forState: .Normal)
        $0.clipsToBounds = true
        $0.insets = CGSize(width: 10, height: 0)
    }
    private let avatarView = specify(StatusUserAvatarView(cornerRadius: 24)) {
        $0.startReceivingStatusUpdates()
        $0.placeholder.font = UIFont.icons(24)
        $0.setBorder()
    }
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        if AddContributorsViewController.darkStyle {
            backgroundColor = Color.grayDarker
        }
        phoneNumbersLabel.numberOfLines = 0
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
        add(phoneNumbersLabel) { (make) -> Void in
            make.top.equalTo(infoLabel.snp_bottom)
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
    
    override func setup(record: ArrangedAddressBookRecord, phoneNumber: AddressBookPhoneNumber) {
        nameLabel.text = record.name
        if let user = record.user {
            avatarView.wrap = wrap
            avatarView.user = user
        } else {
            avatarView.user = nil
            avatarView.url = record.avatar?.small
        }
        infoLabel.text = record.infoString
        phoneNumbersLabel.text = record.phones
        let selected = delegate?.recordCell(self, phoneNumberIsSelected: phoneNumber) ?? false
        selectButton.hidden = record.added
        selectButton.selected = selected
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
    private let openView = specify(Button(icon: "y", size: 18, textColor: Color.grayLighter)) {
        $0.setTitle("z", forState: .Selected)
        $0.contentHorizontalAlignment = .Right
        $0.titleEdgeInsets.right = 13
    }
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        if AddContributorsViewController.darkStyle {
            backgroundColor = Color.grayDarker
        }
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        dataSource = StreamDataSource(streamView: streamView)
        dataSource.addMetrics(StreamMetrics<AddressBookPhoneNumberCell>().change({ [weak self] metrics in
            metrics.size = 50.0
            metrics.selectable = true
            metrics.finalizeAppearing = { item, view in
                let phoneNumber = item.entry as? AddressBookPhoneNumber
                if let weakSelf = self, let phoneNumber = phoneNumber {
                    view.checked = weakSelf.delegate?.recordCell(weakSelf, phoneNumberIsSelected: phoneNumber) ?? false
                }
            }
            metrics.selection = { view in
                self?.selectPhoneNumber(view.entry)
            }
            }))
        openView.addTarget(self, action: #selector(self.open(_:)), forControlEvents: .TouchUpInside)
        avatarView.cornerRadius = 24
        avatarView.setBorder()
        add(avatarView) { (make) -> Void in
            make.leading.top.equalTo(self).inset(12)
            make.size.equalTo(48)
        }
        add(openView) { (make) -> Void in
            make.leading.trailing.top.equalTo(self)
            make.bottom.equalTo(avatarView)
        }
        add(nameLabel) { (make) -> Void in
            make.top.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(self).inset(44)
        }
        let infoLabel = Label(preset: .Smaller, weight: .Regular, textColor: AddContributorsViewController.darkStyle ? .whiteColor() : Color.grayLight)
        infoLabel.text = "invite_me_to_meWrap".ls
        add(infoLabel) { (make) -> Void in
            make.top.equalTo(nameLabel.snp_bottom)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(self).inset(44)
        }
        streamView.scrollEnabled = false
        add(streamView) { (make) -> Void in
            make.leading.trailing.bottom.equalTo(self)
            make.top.equalTo(avatarView.snp_bottom)
        }
    }
    
    override func setup(record: ArrangedAddressBookRecord, phoneNumber: AddressBookPhoneNumber) {
        nameLabel.text = record.name
        avatarView.url = record.avatar?.small
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

final class AddressBookPhoneNumberCell: EntryStreamReusableView<AddressBookPhoneNumber> {
    
    private let selectionView = UIButton(type: .Custom)
    private let typeLabel = Label(preset: .Small, textColor: AddContributorsViewController.darkStyle ? .whiteColor() : Color.grayLight)
    private let phoneLabel = Label(preset: .Small, textColor: AddContributorsViewController.darkStyle ? .whiteColor() : Color.grayLight)
    
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
