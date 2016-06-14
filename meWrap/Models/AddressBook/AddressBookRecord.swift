//
//  AddressBookRecord.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AddressBook

final class AddressBookRecord: CustomStringConvertible {
    
    let name: String
    
    private var _avatar: Asset?
    var avatar: Asset? {
        get {
            if _avatar == nil {
                if  let addressBook = AddressBook.sharedAddressBook.getABAddressBook(), let recordID = recordID where hasImage {
                    let record = ABAddressBookGetPersonWithRecordID(addressBook, recordID)?.takeUnretainedValue()
                    let uid = "addressbook_\(recordID)"
                    let path = ImageCache.defaultCache.getPath(uid)
                    if !ImageCache.defaultCache.contains(uid) {
                        if let imageData = ABPersonCopyImageData(record)?.takeUnretainedValue() {
                            ImageCache.defaultCache.setImageData(imageData, uid:uid)
                        }
                    }
                    let avatar = Asset()
                    avatar.large = path
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
    
    var phoneNumbers = [AddressBookPhoneNumber]()
    
    convenience init?(ABRecord: ABRecordRef) {
        let phones = AddressBookRecord.getPhones(ABRecord)
        if !phones.isEmpty {
            var name: String?
            if let _name = ABRecordCopyCompositeName(ABRecord) {
                name = _name.takeUnretainedValue() as String
            }
            self.init(phoneNumbers: phones, name: name ?? "")
            hasImage = ABPersonHasImageData(ABRecord)
            recordID = ABRecordGetRecordID(ABRecord)
        } else {
            return nil
        }
    }
    
    required init(phoneNumbers: [AddressBookPhoneNumber], name: String) {
        self.name = name
        self.phoneNumbers = phoneNumbers
    }
    
    required init(record: AddressBookRecord) {
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
            let phone = (ABMultiValueCopyValueAtIndex(phones, i)?.takeUnretainedValue() as? String)?.clearPhoneNumber()
            if let phone = phone where phone.characters.count >= Constants.addressBookPhoneNumberMinimumLength {
                let phoneNumber = AddressBookPhoneNumber(phone: phone)
                let phoneLabel: CFStringRef = ABMultiValueCopyLabelAtIndex(phones, i)?.takeUnretainedValue() ?? ""
                let label = ABAddressBookCopyLocalizedLabel(phoneLabel).takeUnretainedValue()
                phoneNumber.label = label as String
                phoneNumbers.append(phoneNumber)
            }
        }
        return phoneNumbers
    }
    
    var description: String {
        return "\(name ?? "") \(phoneNumbers.description)"
    }
}

func ==(lhs: AddressBookPhoneNumber, rhs: AddressBookPhoneNumber) -> Bool {
    if let user = lhs.user {
        return user == rhs.user
    } else {
        return lhs.phone == rhs.phone
    }
}

final class AddressBookPhoneNumber: Hashable, CustomStringConvertible {
    
    let phone: String
    
    init(phone: String) {
        self.phone = phone
    }
    
    var hashValue: Int {
        return phone.hashValue
    }
    
    var label: String?
    
    var user: User?
    
    var activated = false
    
    var description: String {
        return phone ?? ""
    }
}
