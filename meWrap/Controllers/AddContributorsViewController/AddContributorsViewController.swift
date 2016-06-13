//
//  AddContributorsViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 10/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class AddContributorsViewController: BaseViewController, AddressBookRecordCellDelegate, UITextFieldDelegate {
    
    var wrap: Wrap!
    var isBroadcasting: Bool = false
    var isWrapCreation: Bool = false
    var completionHandler: BooleanBlock?
    
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var bottomPrioritizer: LayoutPrioritizer!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    lazy var openedRows = [StreamPosition]()
    lazy var addressBook = ArrangedAddressBook()
    
    var filteredAddressBook: ArrangedAddressBook?
    var singleMetrics: StreamMetrics<SingleAddressBookRecordCell>!
    var multipleMetrics: StreamMetrics<MultipleAddressBookRecordCell>!
    var sectionHeaderMetrics: StreamMetrics<AddressBookGroupView>!
    
    private var contentSizeObserver: NotificationObserver?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.dataSource = self
        
        if isWrapCreation {
            titleLabel.text = "share_with_friends".ls
            nextButton.hidden = self.isBroadcasting
            if self.isBroadcasting {
                nextButton.setTitle("next".ls, forState: .Normal)
            } else {
                nextButton.setTitle("skip".ls, forState: .Normal)
            }
        }
        singleMetrics = specify(StreamMetrics<SingleAddressBookRecordCell>(), {
            $0.modifyItem = { [weak self] item in
                guard let record = item.entry as? AddressBookRecord, let phoneNumber = record.phoneNumbers.last else { return }
                let user = phoneNumber.user
                var leftIdent: CGFloat = 114.0
                if let user = user where self?.wrap.contributors.contains(user) ?? false {
                    leftIdent = 160.0
                }
                let nameHeight = phoneNumber.name?.heightWithFont(UIFont.fontNormal(), width: (self?.streamView.width ?? 0.0) - leftIdent) ?? 0.0
                let inviteHeight = record.infoString?.heightWithFont(UIFont.lightFontSmall(), width: (self?.streamView.width ?? 0.0) - leftIdent) ?? 0
                item.size = max(nameHeight + inviteHeight + 24.0, 72.0)
            }
            $0.prepareAppearing = { [weak self] (item, view) in
                view.wrap = self?.wrap
                view.delegate = self
            }
            $0.selectable = false
            })
        
        multipleMetrics = specify(StreamMetrics<MultipleAddressBookRecordCell>(), { [weak self] metrics in
            metrics.selectable = false
            metrics.modifyItem = { (item) in
                guard let record = item.entry as? AddressBookRecord else { return }
                let nameHeight = record.name?.heightWithFont(UIFont.fontNormal(), width: (self?.streamView.width ?? 0.0) - 142.0) ?? 0.0
                let inviteHeight = "invite_me_to_meWrap".ls.heightWithFont(UIFont.lightFontSmall(), width: (self?.streamView.width ?? 0.0) - 142.0) ?? 0.0
                let heightCell = max(nameHeight + inviteHeight + 16.0, 72.0)
                item.size = self?.openedPosition(item.position) != nil ? heightCell + CGFloat(record.phoneNumbers.count * 50) : heightCell
            }
            metrics.finalizeAppearing = { (item, view) in
                view.delegate = self
                let record = item.entry as? AddressBookRecord
                view.opened = record?.phoneNumbers.count > 1 && self?.openedPosition(item.position) != nil
            }
            })
        
        sectionHeaderMetrics = StreamMetrics<AddressBookGroupView>().change({ [weak self] metrics in
            metrics.size = 32.0
            metrics.modifyItem = { [weak self] (item) in
                if let group = self?.filteredAddressBook?.groups[safe: item.position.section] {
                    item.hidden = group.title?.isEmpty != true && group.records.isEmpty
                } else {
                    item.hidden = true
                }
            }
            metrics.finalizeAppearing = { [weak self] (item, view) in
                view.entry = self?.filteredAddressBook?.groups[safe: item.position.section]
            }
            })
        
        let placeholderMetrics = PlaceholderView.searchPlaceholderMetrics()
        streamView.placeholderMetrics = placeholderMetrics
        placeholderMetrics.selectable = false
        
        spinner.startAnimating()
        let cached = AddressBook.sharedAddressBook.cachedRecords({ [weak self] (array) in
            self?.handleCachedRecords(array)
            self?.spinner.stopAnimating()
            }) { [weak self] records, error in
                self?.handleCachedRecords(records)
                self?.spinner.stopAnimating()
                error?.show()
                AddressBook.sharedAddressBook.updateCachedRecords()
        }
        AddressBook.sharedAddressBook.subscribe(self) { [unowned self] cachedRecords in
            self.handleCachedRecords(cachedRecords)
        }
        if cached {
            AddressBook.sharedAddressBook.updateCachedRecords()
        }
        contentSizeObserver = NotificationObserver.contentSizeCategoryObserver({ [weak self]   (_) in
            self?.streamView.reload()
        })
    }
    
    private func handleCachedRecords(cachedRecords: [AddressBookRecord]) {
        let oldAddressBook = self.addressBook
        self.addressBook = ArrangedAddressBook()
        self.addressBook.addRecords(cachedRecords)
        if oldAddressBook.groups.count != 0 {
            for phoneNumber in oldAddressBook.selectedPhoneNumbers {
                if let phoneNumber = self.addressBook.phoneNumberEqualTo(phoneNumber) {
                    self.addressBook.selectedPhoneNumbers.insert(phoneNumber)
                }
            }
        }
        self.filterContacts()
    }
    
    func filterContacts() {
        if let text = searchField.text {
            filteredAddressBook = addressBook.filter(text)
            streamView.reload()
        }
    }
    
    //MARK: Actions
    
    @IBAction func next(sender: AnyObject) {
        sendInvitation { [weak self] (invited, message) in
            self?.completionHandler?(invited)
        }
    }
    
    private func getInvitees(selectedPhoneNumbers: Set<AddressBookPhoneNumber>) -> Set<Invitee> {
        let registered = selectedPhoneNumbers.filter({ $0.user != nil })
        var invitees = Set<Invitee>(registered.map({
            let invitee: Invitee = insertEntry()
            invitee.user = $0.user
            return invitee
        }))
        
        var unregistered = selectedPhoneNumbers.subtract(registered)
        
        while !unregistered.isEmpty {
            let invitee: Invitee = insertEntry()
            if let phoneNumber = unregistered.first {
                invitee.name = phoneNumber.name
                if let record = phoneNumber.record {
                    let grouped = unregistered.filter({ $0.record == record })
                    invitee.phone = grouped.reduce("", combine: { phones, number -> String in
                        if phones.isEmpty {
                            return phones + "\n" + (number.phone ?? "")
                        } else {
                            return phones + (number.phone ?? "")
                        }
                    })
                    unregistered.subtractInPlace(grouped)
                } else {
                    invitee.phone = phoneNumber.phone
                    unregistered.remove(phoneNumber)
                }
            }
            invitees.insert(invitee)
        }
        return invitees
    }
    
    private func sendInvitation(completionHandler: (invited: Bool, message: String?) -> ()) {
        
        let selectedPhoneNumbers = addressBook.selectedPhoneNumbers
        
        guard let wrap = wrap where !selectedPhoneNumbers.isEmpty else {
            completionHandler(invited: false, message: nil)
            return
        }
        
        let invitees = getInvitees(selectedPhoneNumbers)
        
        let performRequestBlock = { (message: String?) in
            let status = wrap.status
            if status != .InProgress {
                wrap.invitees = invitees
                wrap.invitationMessage = message
                wrap.notifyOnUpdate(.ContributorsChanged)
                if status == .Finished {
                    Uploader.wrapUploader.upload(Uploading.uploading(wrap, type: AddFriendsUploadingType))
                }
                completionHandler(invited: true, message: message)
                if message?.isEmpty ?? true {
                    Toast.show("isn't_using_invite".ls)
                } else {
                    Toast.show("is_using_invite".ls)
                }
            } else {
                Toast.show("publishing_in_progress".ls)
            }
        }
        
        if selectedPhoneNumbers.contains({ $0.user == nil }) {
            let content = String(format: "send_message_to_friends_content".ls, User.currentUser?.name ?? "", wrap.name ?? "")
            ConfirmInvitationView().showInView(view, content: content, success: performRequestBlock, cancel: nil)
        } else {
            performRequestBlock(nil)
        }
    }
    
    @IBAction func done(sender: Button) {
        sendInvitation { [weak self] (invited, message) in
            self?.navigationController?.popViewControllerAnimated(false)
            if invited {
                if message?.isEmpty ?? true {
                    Toast.show("isn't_using_invite".ls)
                } else {
                    Toast.show("is_using_invite".ls)
                }
            }
        }
    }
    
    @IBAction func cancel(sender: AnyObject) {
        addressBook.clearSelection()
        streamView.reload()
        streamView.setNeedsUpdateConstraints()
        bottomPrioritizer.defaultState = true
    }
    
    //MARK: AddressBookRecordCellDelegate
    
    func recordCell(cell: AddressBookRecordCell, phoneNumberState phoneNumber: AddressBookPhoneNumber) -> AddressBookPhoneNumberState {
        if let user = phoneNumber.user where wrap.contributors.contains(user) {
            return .Added
        }
        return addressBook.selectedPhoneNumber(phoneNumber) != nil ? .Selected : .Default
    }
    
    func recordCell(cell: AddressBookRecordCell, didSelectPhoneNumber person: AddressBookPhoneNumber) {
        addressBook.selectPhoneNumber(person)
        let isEmpty = addressBook.selectedPhoneNumbers.count == 0
        if isWrapCreation {
            if isBroadcasting {
                nextButton.hidden = isEmpty
                nextButton.setTitle("next".ls, forState: .Normal)
            } else {
                nextButton.setTitle(isEmpty ? "skip".ls : "finish".ls, forState: .Normal)
            }
            bottomPrioritizer.defaultState = true
        } else {
            bottomPrioritizer.defaultState = isEmpty
        }
        cell.resetup()
    }
    
    func openedPosition(position: StreamPosition) -> StreamPosition? {
        return openedRows[{ $0 == position }]
    }
    
    func recordCellDidToggle(cell: MultipleAddressBookRecordCell) {
        if let position = cell.item?.position {
            if let index = openedRows.indexOf({ $0 == position }) {
                openedRows.removeAtIndex(index)
            } else {
                openedRows.append(position)
            }
            streamView.reload()
        }
    }
    
    //MARK: UITextFieldDelegate
    
    func searchTextChanged(sender: UITextField) {
        filterContacts()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        filterContacts()
        textField.resignFirstResponder()
        return true
    }
}

extension AddContributorsViewController: StreamViewDataSource {
    
    func numberOfSections() -> Int {
        return filteredAddressBook?.groups.count ?? 0
    }
    func numberOfItemsIn(section: Int) -> Int {
        let group = filteredAddressBook?.groups[safe: section]
        return group?.records.count ?? 0
    }
    
    func headerMetricsIn(section: Int) -> [StreamMetricsProtocol] {
        return [sectionHeaderMetrics]
    }
    
    func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [weak self] (item) in
            let group = self?.filteredAddressBook?.groups[safe: item.position.section]
            return group?.records[safe: item.position.index]
        }
    }
    
    func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol] {
        let group = filteredAddressBook?.groups[safe: position.section]
        let record = group?.records[safe: position.index]
        return [record?.phoneNumbers.count > 1 ? multipleMetrics : singleMetrics]
    }
}
