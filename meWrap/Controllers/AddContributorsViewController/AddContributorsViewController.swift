//
//  AddContributorsViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 10/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class AddContributorsViewController: BaseViewController, AddressBookRecordCellDelegate, UITextFieldDelegate, FontPresetting, AddressBookNoifying {
    
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
    var placeholderMetrics: StreamMetrics<PlaceholderView>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.startAnimating()
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
        
        placeholderMetrics = PlaceholderView.searchPlaceholderMetrics()
        placeholderMetrics?.selectable = false
        
        let cached = AddressBook.sharedAddressBook.cachedRecords({ [weak self] (array) in
            self?.addressBook(AddressBook.sharedAddressBook, didUpdateCachedRecords: array)
            self?.spinner.stopAnimating()
            }) { [weak self] (error) in
                self?.spinner.stopAnimating()
                error?.show()
        }
        AddressBook.sharedAddressBook.addReceiver(self)
        if cached {
            AddressBook.sharedAddressBook.updateCachedRecords()
        }
        FontPresetter.defaultPresetter.addReceiver(self)
        
    }
    
    func filterContacts() {
        if let text = searchField.text {
            filteredAddressBook = addressBook.filter(text)
            streamView.reload()
        }
    }
    
    // MARK: - AddressBookReceiver
    
    func addressBook(addressBook: AddressBook, didUpdateCachedRecords cachedRecords: [AddressBookRecord]?) {
        spinner.stopAnimating()
        let oldAddressBook = self.addressBook
        self.addressBook = ArrangedAddressBook()
        if let cachedRecords = cachedRecords {
            self.addressBook.addRecords(cachedRecords)
        }
        if oldAddressBook.groups.count != 0 {
            for phoneNumber in oldAddressBook.selectedPhoneNumbers {
                if let phoneNumber = self.addressBook.phoneNumberEqualTo(phoneNumber) {
                    self.addressBook.selectedPhoneNumbers.insert(phoneNumber)
                }
            }
        }
        filterContacts()
    }
    
    //MARK: Actions
    
    @IBAction func next(sender: AnyObject) {
        if addressBook.selectedPhoneNumbers.count == 0 {
            completionHandler?(false)
        } else {
            if Network.sharedNetwork.reachable != true {
                InfoToast.show("no_internet_connection".ls)
                return
            }
            API.addContributors(addressBook.selectedPhoneNumbers, wrap: wrap, message: nil).send({ [weak self] _ in
                self?.completionHandler?(true)
                }, failure: { error in
                    error?.show()
            })
        }
    }
    
    @IBAction func done(sender: Button) {
        if Network.sharedNetwork.reachable != true {
            InfoToast.show("no_internet_connection".ls)
            return
        }
        let performRequestBlock = { [weak self] (message: AnyObject?) in
            let message = message as? String
            if let selectedPhoneNumbers = self?.addressBook.selectedPhoneNumbers, let wrap = self?.wrap {
                API.addContributors(selectedPhoneNumbers, wrap: wrap, message: message).send({ _ in
                    self?.navigationController?.popViewControllerAnimated(false)
                    if message?.isEmpty ?? true {
                        InfoToast.show("isn't_using_invite".ls)
                    } else {
                        InfoToast.show("is_using_invite".ls)
                    }
                    }, failure: { (error) in
                        error?.show()
                })
            }
        }
        
        if addressBook.selectedPhoneNumbers.count == 0 {
            navigationController?.popViewControllerAnimated(false)
        } else if containUnregisterAddresBookGroupRecord() {
            let content = String(format: "send_message_to_friends_content".ls, User.currentUser?.name ?? "", wrap?.name ?? "")
            ConfirmInvitationView.instance().showInView(view, content: content, success: performRequestBlock, cancel: nil)
        } else {
            performRequestBlock(nil)
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
    
    func containUnregisterAddresBookGroupRecord() -> Bool {
        for phoneNumber in addressBook.selectedPhoneNumbers {
            if phoneNumber.user == nil {
                return true
            }
        }
        return false
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
    
    //MARK: WLFontPresetterReceiver
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        streamView.reload()
    }
}

extension AddContributorsViewController: StreamViewDelegate {
    
    func streamViewNumberOfSections(streamView: StreamView) -> Int {
        return filteredAddressBook?.groups.count ?? 0
    }
    func streamView(streamView: StreamView, numberOfItemsInSection section: Int) -> Int {
        let group = filteredAddressBook?.groups[safe: section]
        return group?.records.count ?? 0
    }
    
    func streamView(streamView: StreamView, headerMetricsInSection section: Int) -> [StreamMetricsProtocol] {
        return [sectionHeaderMetrics]
    }
    
    func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [weak self] (item) in
            let group = self?.filteredAddressBook?.groups[safe: item.position.section]
            return group?.records[safe: item.position.index]
        }
    }
    
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetricsProtocol] {
        let group = filteredAddressBook?.groups[safe: position.section]
        let record = group?.records[safe: position.index]
        return [record?.phoneNumbers.count > 1 ? multipleMetrics : singleMetrics]
    }
    
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetricsProtocol? {
        return placeholderMetrics
    }
}
