//
//  ArrangedAddressBook.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class ArrangedAddressBookGroup: NSObject {
    
    var title: String?
    
    var records = [AddressBookRecord]()
    
    var registered = true
    
    class func registeredGroup() -> ArrangedAddressBookGroup {
        return ArrangedAddressBookGroup(title: "friends_on_meWrap".ls, registered: true)
    }
    
    class func unregisteredGroup() -> ArrangedAddressBookGroup {
        return ArrangedAddressBookGroup(title: "invite_to_meWrap".ls, registered: false)
    }
    
    convenience init(title: String?, registered: Bool) {
        self.init()
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
        if text.nonempty {
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

class ArrangedAddressBook: NSObject {
    
    var groups: [ArrangedAddressBookGroup] = [ArrangedAddressBookGroup.registeredGroup(),ArrangedAddressBookGroup.unregisteredGroup()]
    var selectedPhoneNumbers = Set<AddressBookPhoneNumber>()
    
    func addRecords(records: [AddressBookRecord]) {
        for record in records {
            addRecord(record)
        }
        sort()
    }
    
    func addRecord(var record: AddressBookRecord) {
    
        record = AddressBookRecord(record: record)
        
        if record.phoneNumbers.count == 0 {
            return;
        } else if record.phoneNumbers.count == 1 {
            addRecordToGroup(record)
        } else {
            
            var phoneNumbers = record.phoneNumbers
            
            for (index, phoneNumber) in record.phoneNumbers.enumerate() {
                if let user = phoneNumber.user {
                    let newRecord = AddressBookRecord(phoneNumbers: [phoneNumber])
                    if user.name == nil {
                        newRecord.name = record.name
                    }
                    addRecordToGroup(newRecord)
                    phoneNumbers.removeAtIndex(index)
                }
            }
            
            if phoneNumbers.count != 0 {
                record.phoneNumbers = phoneNumbers
                addRecordToGroup(record)
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
        if (text.nonempty) {
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
