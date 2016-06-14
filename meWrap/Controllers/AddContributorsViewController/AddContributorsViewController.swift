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
    lazy var addressBook: ArrangedAddressBook = ArrangedAddressBook(wrap: self.wrap)
    
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
                guard let record = item.entry as? ArrangedAddressBookRecord else { return }
                let user = record.user
                var leftIdent: CGFloat = 114.0
                if let user = user where self?.wrap.contributors.contains(user) ?? false {
                    leftIdent = 160.0
                }
                let nameHeight = record.name.heightWithFont(UIFont.fontNormal(), width: (self?.streamView.width ?? 0.0) - leftIdent) ?? 0.0
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
                guard let record = item.entry as? ArrangedAddressBookRecord else { return }
                let nameHeight = record.name.heightWithFont(UIFont.fontNormal(), width: (self?.streamView.width ?? 0.0) - 142.0) ?? 0.0
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
                if let group = self?.addressBook.groups[safe: item.position.section] {
                    item.hidden = group.filteredRecords.isEmpty
                } else {
                    item.hidden = true
                }
            }
            metrics.finalizeAppearing = { [weak self] (item, view) in
                view.entry = self?.addressBook.groups[safe: item.position.section]
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
        self.addressBook = ArrangedAddressBook(wrap: wrap, records: cachedRecords)
        addressBook.selectedPhoneNumbers = oldAddressBook.selectedPhoneNumbers
        self.filterContacts()
    }
    
    func filterContacts() {
        addressBook.filter(searchField.text)
        streamView.reload()
    }
    
    //MARK: Actions
    
    @IBAction func next(sender: AnyObject) {
        sendInvitation { [weak self] (invited, message) in
            self?.completionHandler?(invited)
        }
    }
    
    private func getInvitees() -> Set<Invitee> {
        
        var invitees = Set<Invitee>()
        
        for (record, phoneNumbers) in addressBook.selectedPhoneNumbers {
            let invitee: Invitee = insertEntry()
            invitee.wrap = wrap
            if let user = record.user {
                invitee.user = user
            } else {
                invitee.name = record.name
                invitee.phone = phoneNumbers.reduce("", combine: { $0.isEmpty ? $1.phone : $0 + "\n" + $1.phone }) as String
            }
            invitees.insert(invitee)
        }
        
        return invitees
    }
    
    private func sendInvitation(completionHandler: (invited: Bool, message: String?) -> ()) {
        
        guard let wrap = wrap where !addressBook.selectionIsEmpty() else {
            completionHandler(invited: false, message: nil)
            return
        }
        
        let performRequestBlock = { [weak self] (message: String?) in
            let status = wrap.status
            if status != .InProgress {
                self?.getInvitees()
                wrap.invitationMessage = message
                wrap.notifyOnUpdate(.ContributorsChanged)
                if status == .Finished {
                    Uploader.wrapUploader.upload(Uploading.uploading(wrap, type: AddFriendsUploadingType))
                }
                completionHandler(invited: true, message: message)
            } else {
                Toast.show("publishing_in_progress".ls)
            }
        }
        
        if addressBook.selectedPhoneNumbers.contains({ (record, _) in record.user == nil }) {
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
                if Network.network.reachable {
                    if message?.isEmpty ?? true {
                        Toast.show("isn't_using_invite".ls)
                    } else {
                        Toast.show("is_using_invite".ls)
                    }
                } else {
                    Toast.show("offline_invitation_message".ls)
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
    
    func recordCell(cell: AddressBookRecordCell, phoneNumberIsSelected phoneNumber: AddressBookPhoneNumber) -> Bool {
        guard let record = cell.entry else { return false }
        return addressBook.selectedPhoneNumbers[record]?.contains(phoneNumber) == true
    }
    
    func recordCell(cell: AddressBookRecordCell, didSelectPhoneNumber phoneNumber: AddressBookPhoneNumber) {
        guard let record = cell.entry else { return }
        addressBook.selectPhoneNumber(record, phoneNumber: phoneNumber)
        let isEmpty = addressBook.selectionIsEmpty()
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
        return addressBook.groups.count
    }
    func numberOfItemsIn(section: Int) -> Int {
        let group = addressBook.groups[safe: section]
        return group?.filteredRecords.count ?? 0
    }
    
    func headerMetricsIn(section: Int) -> [StreamMetricsProtocol] {
        return [sectionHeaderMetrics]
    }
    
    func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [weak self] (item) in
            let group = self?.addressBook.groups[safe: item.position.section]
            return group?.filteredRecords[safe: item.position.index]
        }
    }
    
    func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol] {
        let group = addressBook.groups[safe: position.section]
        let record = group?.filteredRecords[safe: position.index]
        return [record?.phoneNumbers.count > 1 ? multipleMetrics : singleMetrics]
    }
}
