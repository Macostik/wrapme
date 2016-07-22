//
//  AddContributorsViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 10/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class AddContributorsViewController: BaseViewController, AddressBookRecordCellDelegate, UITextFieldDelegate, StreamViewDataSource {
    
    static var darkStyle = false
    
    let wrap: Wrap?
    required init(wrap: Wrap?) {
        self.wrap = wrap
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isWrapCreation: Bool = false
    var completionHandler: BooleanBlock?
    
    internal let streamView = StreamView()
    internal let searchField = TextField()
    internal let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
    internal let nextButton = Button(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
    
    private lazy var openedRows = [StreamPosition]()
    internal lazy var addressBook: ArrangedAddressBook = ArrangedAddressBook(wrap: self.wrap)
    
    private var singleMetrics: StreamMetrics<SingleAddressBookRecordCell>!
    private var multipleMetrics: StreamMetrics<MultipleAddressBookRecordCell>!
    
    private let buttonsView = UIView()
    
    override func loadView() {
        super.loadView()
        AddContributorsViewController.darkStyle = false
        view.backgroundColor = UIColor.whiteColor()
        let navigationBar = UIView()
        navigationBar.backgroundColor = Color.orange
        self.navigationBar = view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        let back = navigationBar.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        back.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        back.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        nextButton.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        nextButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        let title = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        navigationBar.add(nextButton) { (make) in
            make.trailing.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
            make.leading.greaterThanOrEqualTo(back.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(nextButton.snp_leading).offset(-12)
        }
        self.navigationBar = navigationBar
        
        let searchView = UIView()
        view.add(searchView) { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(navigationBar.snp_bottom)
            make.height.equalTo(44)
        }
        
        let searchIcon = Label(icon: "I", size: 17, textColor: Color.orange)
        searchIcon.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        searchIcon.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        searchView.add(searchIcon) { (make) in
            make.trailing.equalTo(searchView).offset(-12)
            make.centerY.equalTo(searchView)
        }
        
        searchField.font = Font.Small + .Light
        searchField.makePresetable(.Small)
        searchField.disableSeparator = true
        searchField.delegate = self
        searchField.placeholder = "search_contacts".ls
        searchField.addTarget(self, action: #selector(self.searchTextChanged(_:)), forControlEvents: .EditingChanged)
        searchView.add(searchField) { (make) in
            make.leading.equalTo(searchView).offset(12)
            make.top.bottom.equalTo(searchView)
            make.trailing.equalTo(searchIcon.snp_leading).offset(-12)
        }
        
        searchView.add(SeparatorView(color: Color.grayLightest, contentMode: .Bottom)) { (make) in
            make.leading.bottom.trailing.equalTo(searchView)
            make.height.equalTo(1)
        }
        
        view.add(streamView) { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(searchView.snp_bottom)
        }
        
        if isWrapCreation {
            nextButton.addTarget(self, touchUpInside: #selector(self.next(_:)))
            title.text = "share_with_friends".ls
            nextButton.hidden = false
            nextButton.setTitle("skip".ls, forState: .Normal)
        } else {
            title.text = "add_friends".ls
            nextButton.hidden = true
        }
        
        buttonsView.hidden = true
        buttonsView.backgroundColor = UIColor.whiteColor()
        let cancelButton = Button(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        cancelButton.normalColor = Color.orange
        cancelButton.backgroundColor = cancelButton.normalColor
        cancelButton.highlightedColor = Color.orangeDark
        cancelButton.setTitle("cancel".ls, forState: .Normal)
        cancelButton.addTarget(self, touchUpInside: #selector(self.cancel(_:)))
        let doneButton = Button(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        doneButton.normalColor = Color.orange
        doneButton.backgroundColor = cancelButton.normalColor
        doneButton.highlightedColor = Color.orangeDark
        doneButton.setTitle("done".ls, forState: .Normal)
        doneButton.addTarget(self, touchUpInside: #selector(self.done(_:)))
        view.add(buttonsView) { (make) in
            make.bottom.equalTo(streamView)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(44)
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
        buttonsView.add(cancelButton) { (make) in
            make.leading.top.bottom.equalTo(buttonsView)
        }
        buttonsView.add(doneButton) { (make) in
            make.trailing.top.bottom.equalTo(buttonsView)
            make.width.equalTo(cancelButton)
            make.leading.equalTo(cancelButton.snp_trailing).offset(1)
        }
        
        streamView.placeholderViewBlock = PlaceholderView.searchPlaceholder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.add(spinner) {
            $0.center.equalTo(streamView)
        }
        
        streamView.dataSource = self
        
        singleMetrics = specify(StreamMetrics<SingleAddressBookRecordCell>(), {
            $0.modifyItem = { item in
                guard let record = item.entry as? ArrangedAddressBookRecord else { return }
                let nameHeight = UIFont.fontNormal().lineHeight
                let inviteHeight = UIFont.fontSmaller().lineHeight
                let phonesHeight = CGFloat(record.numberOfPhones) * UIFont.fontSmaller().lineHeight
                item.size = max(nameHeight + inviteHeight + phonesHeight + 24.0, 72.0)
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
                item.size = self?.openedPosition(item.position) != nil ? 60 + CGFloat(record.phoneNumbers.count * 50) : 72
            }
            metrics.finalizeAppearing = { (item, view) in
                view.delegate = self
                let record = item.entry as? AddressBookRecord
                view.opened = record?.phoneNumbers.count > 1 && self?.openedPosition(item.position) != nil
            }
            })
        
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
        FontPresetter.presetter.subscribe(self) { [unowned self] (value) in
            self.streamView.reload()
        }
    }
    
    private func handleCachedRecords(cachedRecords: [AddressBookRecord]) {
        let oldAddressBook = self.addressBook
        self.addressBook = ArrangedAddressBook(wrap: wrap, records: cachedRecords)
        addressBook.selectedPhoneNumbers = oldAddressBook.selectedPhoneNumbers
        streamView.reload()
    }
    
    //MARK: Actions
    
    @IBAction func next(sender: AnyObject) {
        if searchField.isFirstResponder() {
            searchField.resignFirstResponder()
        }
        sendInvitation { [weak self] (invited, message) in
            self?.completionHandler?(invited)
        }
    }
    
    func getInvitees(wrap: Wrap?) -> Set<Invitee> {
        
        var invitees = Set<Invitee>()
        
        for (record, phoneNumbers) in addressBook.selectedPhoneNumbers {
            let invitee: Invitee = insertEntry()
            invitee.wrap = wrap
            invitee.name = record.name
            if let user = record.user {
                invitee.user = user
            } else {
                invitee.phone = phoneNumbers.reduce("", combine: { $0.isEmpty ? $1.phone : $0 + "\n" + $1.phone }) as String
            }
            invitees.insert(invitee)
        }
        
        return invitees
    }
    
    private func sendInvitation(completionHandler: (invited: Bool, message: String?) -> ()) {
        
        guard let wrap = self.wrap where !addressBook.selectionIsEmpty() else {
            completionHandler(invited: false, message: nil)
            return
        }
        
        let performRequestBlock = { [weak self] (message: String?) in
            let status = wrap.status
            if status != .InProgress {
                self?.getInvitees(self?.wrap)
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
        if searchField.isFirstResponder() {
            searchField.resignFirstResponder()
        }
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
        if searchField.isFirstResponder() {
            searchField.resignFirstResponder()
        }
        addressBook.clearSelection()
        streamView.reload()
        streamView.setNeedsUpdateConstraints()
        buttonsView.hidden = true
        streamView.contentInset.bottom = 0
    }
    
    //MARK: AddressBookRecordCellDelegate
    
    func recordCell(cell: AddressBookRecordCell, phoneNumberIsSelected phoneNumber: AddressBookPhoneNumber) -> Bool {
        guard let record = cell.entry else { return false }
        return addressBook.selectedPhoneNumbers[record]?.contains(phoneNumber) == true
    }
    
    func recordCell(cell: AddressBookRecordCell, didSelectPhoneNumber phoneNumber: AddressBookPhoneNumber) {
        
        if searchField.isFirstResponder() {
            searchField.resignFirstResponder()
        }
        
        guard let record = cell.entry else { return }
        addressBook.selectPhoneNumber(record, phoneNumber: phoneNumber)
        let isEmpty = addressBook.selectionIsEmpty()
        if isWrapCreation {
            nextButton.addTarget(self, touchUpInside: #selector(self.next(_:)))
            nextButton.setTitle(isEmpty ? "skip".ls : "finish".ls, forState: .Normal)
            buttonsView.hidden = true
        } else {
            buttonsView.hidden = isEmpty
            streamView.contentInset.bottom = isEmpty ? 0 : 44
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
        streamView.reload()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        streamView.reload()
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - StreamViewDataSource
    
    func numberOfItemsIn(section: Int) -> Int {
        return addressBook.records.count
    }
    
    func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [weak self] (item) in
            return self?.addressBook.records[safe: item.position.index]
        }
    }
    
    func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol] {
        guard let record = addressBook.records[safe: position.index] else { return [] }
        if let text = searchField.text where !text.isEmpty && record.name.rangeOfString(text, options: .CaseInsensitiveSearch, range: nil, locale: nil) == nil {
            return []
        }
        return [record.phoneNumbers.count > 1 ? multipleMetrics : singleMetrics]
    }
}
