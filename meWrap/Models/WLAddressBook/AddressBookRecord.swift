//
//  AddressBookRecord.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AddressBook

class AddressBookRecord: NSObject {
    
    var name: String?
    
    private var _avatar: Asset?
    var avatar: Asset? {
        get {
            if _avatar == nil {
                if  let addressBook = WLAddressBook.sharedAddressBook().ABAddressBook(), let recordID = recordID where hasImage {
                    let record = ABAddressBookGetPersonWithRecordID(addressBook.takeUnretainedValue(), recordID)?.takeUnretainedValue()
                    let uid = "addressbook_\(recordID)"
                    let path = ImageCache.defaultCache.getPath(uid)
                    if !ImageCache.defaultCache.contains(uid) {
                        if let imageData = ABPersonCopyImageData(record)?.takeUnretainedValue() {
                            ImageCache.defaultCache.setImageData(imageData, uid:uid)
                        }
                    }
                    let avatar = Asset()
                    avatar.large = path
                    avatar.medium = path
                    avatar.small = path
                    _avatar = avatar
                }
            }
            return _avatar
        }
        set {
            _avatar = newValue
        }
    }
    
    var recordID: ABRecordID?
    
    var hasImage = false
    
    var registered: Bool {
        return phoneNumbers.first?.user != nil
    }
    
    var phoneNumbers = [AddressBookPhoneNumber]() {
        didSet {
            for phoneNumber in phoneNumbers {
                phoneNumber.record = self
            }
        }
    }
    
    var phoneStrings: String? {
        if let phoneNumber = phoneNumbers.last {
            if let user = phoneNumber.user where user.valid {
                return user.phones
            } else {
                return phoneNumber.phone
            }
        }
        return nil
    }
    
    convenience init?(ABRecord: ABRecordRef) {
        self.init()
        let phones = AddressBookRecord.getPhones(ABRecord)
        if !phones.isEmpty {
            hasImage = ABPersonHasImageData(ABRecord)
            recordID = ABRecordGetRecordID(ABRecord)
            if let name = ABRecordCopyCompositeName(ABRecord) {
                self.name = name.takeUnretainedValue() as String
            }
            phoneNumbers = phones
        } else {
            return nil
        }
    }
    
    convenience init(phoneNumbers: [AddressBookPhoneNumber]) {
        self.init()
        self.phoneNumbers = phoneNumbers
    }
    
    convenience init(record: AddressBookRecord) {
        self.init()
        hasImage = record.hasImage
        recordID = record.recordID
        name = record.name
        _avatar = record._avatar
        phoneNumbers = record.phoneNumbers
    }
    
    private class func getPhones(ABRecord: ABRecordRef) -> [AddressBookPhoneNumber] {
        var phoneNumbers = [AddressBookPhoneNumber]()
        let phones = ABRecordCopyValue(ABRecord, kABPersonPhoneProperty)?.takeUnretainedValue()
        let count = ABMultiValueGetCount(phones)
        for i in 0...count {
            let phoneNumber = AddressBookPhoneNumber()
            let phone = (ABMultiValueCopyValueAtIndex(phones, i)?.takeUnretainedValue() as? String)?.clearPhoneNumber()
            
            if let phone = phone where phone.characters.count >= Constants.addressBookPhoneNumberMinimumLength {
                phoneNumber.phone = phone
                let phoneLabel: CFStringRef = ABMultiValueCopyLabelAtIndex(phones, i)?.takeUnretainedValue() ?? ""
                let label = ABAddressBookCopyLocalizedLabel(phoneLabel).takeUnretainedValue()
                phoneNumber.label = label as String
                phoneNumbers.append(phoneNumber)
            }
        }
        return phoneNumbers
    }
    
    override var description: String {
        return "\(name ?? "") \(phoneNumbers.description)"
    }
}

class AddressBookPhoneNumber: NSObject {
    
    weak var record: AddressBookRecord?
    
    var phone = ""
    
    private var _name: String?
    var name: String? {
        get {
            if _name == nil {
                if let name = user?.name {
                    _name = name
                } else if let name = record?.name {
                    _name = name
                } else {
                    _name = phone
                }
            }
            return _name
        }
        set {
            _name = newValue
        }
    }
    
    var label: String?
    
    var user: User?
    
    private var _avatar: Asset?
    var avatar: Asset? {
        get {
            if _avatar == nil {
                if user?.avatar?.small != nil {
                    _avatar = user?.avatar
                } else {
                    _avatar = record?.avatar
                }
            }
            return _avatar
        }
        set {
            _avatar = newValue
        }
    }
    
    var activated = false
    
    func isEqualToPhoneNumber(phoneNumber: AddressBookPhoneNumber) -> Bool {
        if let user = user {
            return user == phoneNumber.user
        } else {
            return phone == phoneNumber.phone
        }
    }
    
    override var description: String {
        return phone ?? ""
    }
}
