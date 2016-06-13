//
//  ArrangedAddressBook.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

final class ArrangedAddressBookGroup {
    
    let title: String
    
    var records = [AddressBookRecord]()
    
    let registered: Bool
    
    static func registeredGroup() -> ArrangedAddressBookGroup {
        return ArrangedAddressBookGroup(title: "friends_on_meWrap".ls, registered: true)
    }
    
    static func unregisteredGroup() -> ArrangedAddressBookGroup {
        return ArrangedAddressBookGroup(title: "invite_to_meWrap".ls, registered: false)
    }
    
    init(title: String, registered: Bool) {
        self.title = title
        self.registered = registered
    }
    
    func add(record: AddressBookRecord) -> Bool {
        if record.registered == registered {
            records.append(record)
            return true
        } else {
            return false
        }
    }
    
    func sort() {
        records.sortInPlace { (r1, r2) -> Bool in
            let pn1 = r1.phoneNumbers.last
            let pn2 = r2.phoneNumbers.last
            
            if let name1 = pn1?.name, let name2 = pn2?.name where !name1.isEmpty && !name2.isEmpty {
                return pn1?.name < pn2?.name
            }
            return r1.hashValue < r2.hashValue
        }
    }
    
    func filter(text: String) -> ArrangedAddressBookGroup {
        if !text.isEmpty {
            let group = ArrangedAddressBookGroup(title: title, registered: registered)
            group.records = records.filter({ $0.phoneNumbers.last?.name?.rangeOfString(text, options: .CaseInsensitiveSearch, range: nil, locale: nil) != nil })
            return group
        } else {
            return self
        }
    }
    
    func phoneNumberEqualTo(phoneNumber:AddressBookPhoneNumber) -> AddressBookPhoneNumber? {
        for record in records {
            for _phoneNumber in record.phoneNumbers where _phoneNumber == phoneNumber {
                return _phoneNumber
            }
        }
        return nil
    }
}

final class ArrangedAddressBook {
    
    var groups: [ArrangedAddressBookGroup] = [ArrangedAddressBookGroup.registeredGroup(),ArrangedAddressBookGroup.unregisteredGroup()]
    var selectedPhoneNumbers = Set<AddressBookPhoneNumber>()
    
    func addRecords(records: [AddressBookRecord]) {
        for record in records {
            addRecord(record)
        }
        sort()
    }
    
    func addRecord(record: AddressBookRecord) {
        var _record = record
        _record = AddressBookRecord(record: _record)
        
        if _record.phoneNumbers.count == 0 {
            return;
        } else if _record.phoneNumbers.count == 1 {
            addRecordToGroup(_record)
        } else {
            
            var phoneNumbers = _record.phoneNumbers
            
            for phoneNumber in _record.phoneNumbers {
                if let user = phoneNumber.user {
                    let newRecord = AddressBookRecord(phoneNumbers: [phoneNumber])
                    if user.name == nil {
                        newRecord.name = _record.name
                    }
                    addRecordToGroup(newRecord)
                    if let index = phoneNumbers.indexOf(phoneNumber) {
                        phoneNumbers.removeAtIndex(index)
                    }
                }
            }
            
            if phoneNumbers.count != 0 {
                _record.phoneNumbers = phoneNumbers
                addRecordToGroup(_record)
            }
        }
    }
    
    func addRecordToGroup(record: AddressBookRecord) {
        for group in groups where group.add(record) { break }
    }
    
    func sort() {
        for group in groups { group.sort() }
    }
    
    func selectPhoneNumber(phoneNumber: AddressBookPhoneNumber) {
        if let index = selectedPhoneNumbers.indexOf({ $0 == phoneNumber }) {
            selectedPhoneNumbers.removeAtIndex(index)
        } else {
            selectedPhoneNumbers.insert(phoneNumber)
        }
    }
    
    func selectedPhoneNumber(phoneNumber: AddressBookPhoneNumber) -> AddressBookPhoneNumber? {
        for _phoneNumber in selectedPhoneNumbers where _phoneNumber == phoneNumber {
            return _phoneNumber
        }
        return nil
    }
    
    func filter(text: String) -> ArrangedAddressBook {
        if !text.isEmpty {
            let addressBook = ArrangedAddressBook()
            addressBook.groups = groups.map({ $0.filter(text) })
            return addressBook
        } else {
            return self;
        }
    }
    
    func phoneNumberEqualTo(phoneNumber: AddressBookPhoneNumber) -> AddressBookPhoneNumber? {
        for group in groups {
            if let _phoneNumber = group.phoneNumberEqualTo(phoneNumber) {
                return _phoneNumber
            }
        }
        return nil
    }
    
    func clearSelection() {
        selectedPhoneNumbers.removeAll()
    }
}
