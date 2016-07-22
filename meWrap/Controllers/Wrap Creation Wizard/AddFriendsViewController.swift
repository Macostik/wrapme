//
//  AddFriendsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 6/29/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

protocol SelectedAddressBookRecordCellDelegate: class {
    func selectedRecordCell(cell: SelectedAddressBookRecordCell, phoneNumbersFor record: ArrangedAddressBookRecord) -> [AddressBookPhoneNumber]
    func selectedRecordCell(cell: SelectedAddressBookRecordCell, didRemove record: ArrangedAddressBookRecord)
}

class SelectedAddressBookRecordCell: EntryStreamReusableView<ArrangedAddressBookRecord> {
    
    weak var delegate: SelectedAddressBookRecordCellDelegate?
    
    internal let nameLabel = Label(preset: .Normal, weight: .Semibold, textColor: AddContributorsViewController.darkStyle ? .whiteColor() : Color.grayDark)
    
    private let infoLabel = Label(preset: .Smaller, weight: .Regular, textColor: AddContributorsViewController.darkStyle ? .whiteColor() : Color.grayLight)
    private let phoneNumbersLabel = Label(preset: .Smaller, weight: .Regular, textColor: AddContributorsViewController.darkStyle ? Color.grayLighter : Color.grayLight)
    private let removeButton = specify(Button(icon: "!", size: 18)) {
        $0.setTitleColor(Color.grayLighter, forState: .Highlighted)
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
        infoLabel.numberOfLines = 0
        removeButton.addTarget(self, action: #selector(self.remove(_:)), forControlEvents: .TouchUpInside)
        infoLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        add(avatarView) { (make) -> Void in
            make.leading.top.equalTo(self).offset(12)
            make.size.equalTo(48)
        }
        add(removeButton) { (make) -> Void in
            make.trailing.equalTo(self).offset(-12)
            make.centerY.equalTo(avatarView)
        }
        add(nameLabel) { (make) -> Void in
            make.top.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(removeButton.snp_leading)
        }
        add(infoLabel) { (make) -> Void in
            make.top.equalTo(nameLabel.snp_bottom)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(removeButton.snp_leading)
        }
        phoneNumbersLabel.numberOfLines = 0
        add(phoneNumbersLabel) { (make) -> Void in
            make.top.equalTo(infoLabel.snp_bottom)
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(removeButton.snp_leading)
        }
    }
    
    weak var wrap: Wrap?
    
    override func setup(record: ArrangedAddressBookRecord) {
        
        nameLabel.text = record.name
        if let user = record.user {
            avatarView.wrap = wrap
            avatarView.user = user
        } else {
            avatarView.user = nil
            avatarView.url = record.avatar?.small
        }
        infoLabel.text = record.infoString
        if let user = record.user {
            phoneNumbersLabel.text = user.phones
        } else {
            guard let phoneNumbers = delegate?.selectedRecordCell(self, phoneNumbersFor: record) else { return }
            let phones = phoneNumbers.reduce("", combine: {
                return $0.isEmpty ? ($0 + $1.phone) : ($0 + "\n" + $1.phone)
            })
            phoneNumbersLabel.text = phones
        }
    }
    
    //MARK: Actions
    
    @IBAction func remove(sender: AnyObject) {
        guard let record = entry else { return }
        delegate?.selectedRecordCell(self, didRemove: record)
    }
}

final class AddFriendsViewController: AddContributorsViewController, SelectedAddressBookRecordCellDelegate {
    
    var p2p = false
    
    let backgroundImageView = UIImageView()
    
    var completionBlock: (Wrap? -> ())?
    
    internal let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
    
    internal lazy var backButton: Button = self.backButton(UIColor.whiteColor(), action: #selector(self.backAction(_:)))
    
    private let plusButton = Button(icon: "~", size: 15, textColor: Color.orange)
    
    private var selectedRecordMetrics: StreamMetrics<SelectedAddressBookRecordCell>!
    
    let titleLabel = Label(preset: .Large, weight: .Semibold, textColor: UIColor.whiteColor())
    
    private var doneLabel: Label?
    
    let topView = UIView()
    
    override func loadView() {
        AddContributorsViewController.darkStyle = true
        view = UIView(frame: preferredViewFrame)
        view.backgroundColor = Color.grayDarker
        backgroundImageView.contentMode = .ScaleAspectFill
        view.add(backgroundImageView) { (make) in
            make.edges.equalTo(view)
        }
        view.add(blurView) { $0.edges.equalTo(view) }
        nextButton.hidden = true
        
        topView.backgroundColor = Color.grayDarker
        view.addSubview(topView)
        
        topView.add(backButton) { (make) in
            make.leading.equalTo(topView).offset(12)
            make.centerY.equalTo(topView.snp_top).offset(42)
        }
        doneLabel = nextButton.makeWizardButton(with: "create".ls).label
        
        nextButton.addTarget(self, touchUpInside: #selector(self.next(_:)))
        topView.add(nextButton) { (make) in
            make.trailing.equalTo(topView).offset(-12)
            make.centerY.equalTo(backButton)
        }
        
        topView.addSubview(titleLabel)
        
        updateAddingState()
        
        searchField.returnKeyType = .Done
        searchField.textColor = UIColor.whiteColor()
        searchField.font = Font.Large + .Regular
        searchField.makePresetable(.Large)
        searchField.attributedPlaceholder = NSAttributedString(string: "type_friends_name".ls, attributes: [NSForegroundColorAttributeName: Color.grayLighter, NSFontAttributeName: Font.Normal + .Light])
        searchField.delegate = self
        searchField.strokeColor = UIColor.whiteColor()
        searchField.highlightedStrokeColor = Color.orange
        searchField.addTarget(self, action: #selector(self.searchTextChanged(_:)), forControlEvents: .EditingChanged)
        searchField.rightViewMode = .Always
        topView.add(searchField) { (make) in
            make.leading.equalTo(backButton.snp_trailing)
            make.centerX.equalTo(view)
            make.centerY.equalTo(topView.snp_bottom).offset(-32)
            make.height.equalTo(32)
        }
        
        plusButton.addTarget(self, touchUpInside: #selector(self.showContacts))
        plusButton.frame = (0 ^ 0) ^ (32 ^ 32)
        searchField.rightView = plusButton
        
        view.insertSubview(streamView, belowSubview: topView)
        streamView.alwaysBounceVertical = true
        streamView.placeholderViewBlock = nil
        streamView.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(topView.snp_bottom)
            let bottom = make.bottom.equalTo(view).constraint
            Keyboard.keyboard.handle(self, willShow: { [unowned self] (keyboard) in
                keyboard.performAnimation({ () in
                    bottom.updateOffset(-keyboard.height)
                    self.view.layoutIfNeeded()
                })
            }) { [unowned self] (keyboard) in
                keyboard.performAnimation({ () in
                    bottom.updateOffset(0)
                    self.view.layoutIfNeeded()
                })
            }
        }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = topView.backgroundColor
        streamView.add(backgroundView) { (make) in
            make.size.equalTo(streamView)
            make.centerX.equalTo(streamView)
            make.bottom.equalTo(streamView.snp_top)
        }
        
        let refresher = Refresher(scrollView: streamView)
        refresher.style = .White
        refresher.addTarget(self, action: #selector(self.refresh(_:)), forControlEvents: .ValueChanged)
        
        selectedRecordMetrics = specify(StreamMetrics(), {
            $0.prepareAppearing = { [weak self] item, view in
                view.delegate = self
            }
            $0.modifyItem = { [weak self] item in
                guard let record = item.entry as? ArrangedAddressBookRecord else { return }
                if record.user != nil {
                    item.size = max(UIFont.fontNormal().lineHeight + UIFont.fontSmaller().lineHeight + (CGFloat(record.numberOfPhones) * UIFont.fontSmaller().lineHeight) + 24, 72)
                } else {
                    let phoneNumbers = self?.addressBook.selectedPhoneNumbers[record] ?? []
                    item.size = max(UIFont.fontNormal().lineHeight + UIFont.fontSmaller().lineHeight + (CGFloat(phoneNumbers.count) * UIFont.lightFontSmaller().lineHeight) + 24, 72)
                }
            }
        })
    }
    
    func refresh(sender: Refresher) {
        AddressBook.sharedAddressBook.records({ _ in
            sender.setRefreshing(false, animated: true)
            }) { (_, error) in
                error?.show()
                sender.setRefreshing(false, animated: true)
        }
    }
    
    private var showAllContacts = false {
        didSet {
            streamView.reload()
            searchField.rightView = showAllContacts ? nil : plusButton
            let isEmpty = addressBook.selectionIsEmpty()
            updateNextButton(isEmpty)
            disableAdding = p2p && !isEmpty && !showAllContacts
            streamView.backgroundColor = showAllContacts ? Color.grayDarker : .clearColor()
        }
    }
    
    private func updateNextButton(addressBookIsEmpty: Bool) {
        let textIsEmpty = searchField.text?.isEmpty == true
        nextButton.hidden = showAllContacts ? false : (addressBookIsEmpty && textIsEmpty)
        if p2p && existingWrap != nil {
            doneLabel?.text = (showAllContacts || !textIsEmpty) ? "done".ls : "open".ls
        } else {
            doneLabel?.text = (showAllContacts || !textIsEmpty) ? "done".ls : "create".ls
        }
    }
    
    func showContacts() {
        showAllContacts = true
    }
    
    private var selectedRecords: [ArrangedAddressBookRecord] = []
    
    override func numberOfItemsIn(section: Int) -> Int {
        if showAllContacts || searchField.text?.isEmpty == false {
            return addressBook.records.count
        } else {
            selectedRecords = addressBook.selectedPhoneNumbers.keys.sort({ $0.name < $1.name })
            return selectedRecords.count
        }
    }
    
    override func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol] {
        if showAllContacts || searchField.text?.isEmpty == false {
            return super.metricsAt(position)
        } else {
            return [selectedRecordMetrics]
        }
    }
    
    override func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)? {
        if showAllContacts || searchField.text?.isEmpty == false {
            return super.entryBlockForItem(item)
        } else {
            return { [weak self] item in
                return self?.selectedRecords[safe: item.position.index]
            }
        }
    }
    
    private weak var existingWrap: Wrap?
    
    private var disableAdding = false {
        didSet {
            guard disableAdding != oldValue else { return }
            updateAddingState()
        }
    }
    
    private func updateAddingState() {
        if disableAdding {
            backButton.hidden = true
            searchField.hidden = true
            titleLabel.snp_remakeConstraints { (make) in
                make.leading.equalTo(view).offset(12)
                make.centerY.equalTo(backButton)
                make.trailing.lessThanOrEqualTo(nextButton.snp_leading).offset(-12)
            }
            topView.snp_remakeConstraints { (make) in
                make.leading.top.trailing.equalTo(view)
                make.height.equalTo(64)
            }
            titleLabel.text = nil
            let name = "@\(addressBook.selectedPhoneNumbers.keys.first?.name ?? "")"
            let title = String(format: (existingWrap != nil ? "f_wrap_found".ls : "f_create".ls), name)
            let titleText = NSMutableAttributedString(string: title, attributes: [NSFontAttributeName: UIFont.fontNormal(), NSForegroundColorAttributeName: UIColor.whiteColor()])
            titleText.addAttributes([NSFontAttributeName: UIFont.fontNormal(), NSForegroundColorAttributeName: Color.orange], range: (title as NSString).rangeOfString(name))
            titleLabel.attributedText = titleText
        } else {
            backButton.hidden = false
            searchField.hidden = false
            titleLabel.snp_remakeConstraints { (make) in
                make.leading.equalTo(backButton.snp_trailing).offset(12)
                make.centerY.equalTo(backButton)
                make.trailing.lessThanOrEqualTo(nextButton.snp_leading).offset(-12)
            }
            topView.snp_remakeConstraints { (make) in
                make.leading.top.trailing.equalTo(view)
                make.height.equalTo(115)
            }
            titleLabel.attributedText = nil
            titleLabel.text = p2p ? "add_friend_to_wrap".ls : "add_friends_to_wrap".ls
        }
    }
    
    override func recordCell(cell: AddressBookRecordCell, didSelectPhoneNumber phoneNumber: AddressBookPhoneNumber) {
        if !p2p || addressBook.selectionIsEmpty() {
            super.recordCell(cell, didSelectPhoneNumber: phoneNumber)
        }
        let isEmpty = addressBook.selectionIsEmpty()
        if !isEmpty && p2p {
            let record = cell.entry
            existingWrap = User.currentUser?.wraps.filter({ wrap in
                guard wrap.p2p else { return false }
                if let user = record?.user {
                    return wrap.contributors.contains(user) || wrap.invitees.contains({ $0.user == user })
                } else {
                    return wrap.invitees.contains({ $0.phones.contains(phoneNumber.phone) })
                }
            }).first
            searchField.text = ""
            if showAllContacts {
                showAllContacts = false
            }
            disableAdding = true
        } else {
            disableAdding = false
        }
        updateNextButton(isEmpty)
    }
    
    func backAction(sender: UIButton) {
        if showAllContacts {
            searchField.text = ""
            showAllContacts = false
        } else {
            navigationController?.popViewControllerAnimated(false)
        }
    }
    
    override func searchTextChanged(sender: UITextField) {
        super.searchTextChanged(sender)
        updateNextButton(addressBook.selectionIsEmpty())
    }
    
    override func next(sender: AnyObject) {
        if showAllContacts {
            searchField.text = ""
            showAllContacts = false
        } else if searchField.text?.isEmpty == false {
            if searchField.isFirstResponder() {
                searchField.resignFirstResponder()
            }
            searchField.text = ""
            updateNextButton(addressBook.selectionIsEmpty())
            streamView.reload()
        } else {
            completionBlock?(existingWrap)
        }
    }
    
    // MARK: - SelectedAddressBookRecordCellDelegate
    
    func selectedRecordCell(cell: SelectedAddressBookRecordCell, didRemove record: ArrangedAddressBookRecord) {
        addressBook.selectedPhoneNumbers[record] = nil
        streamView.reload()
        let isEmpty = addressBook.selectionIsEmpty()
        updateNextButton(isEmpty)
        if p2p {
            disableAdding = false
        }
    }
    
    func selectedRecordCell(cell: SelectedAddressBookRecordCell, phoneNumbersFor record: ArrangedAddressBookRecord) -> [AddressBookPhoneNumber] {
        return addressBook.selectedPhoneNumbers[record] ?? []
    }
}