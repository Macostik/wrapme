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
    
    var records = [ArrangedAddressBookRecord]()
    var filteredRecords = [ArrangedAddressBookRecord]()
    
    init(title: String) {
        self.title = title
    }
    
    func add(record: ArrangedAddressBookRecord) {
        records.append(record)
    }
    
    func sort() {
        records.sortInPlace { $0.name < $1.name }
    }
    
    func filter(text: String?) {
        if let text = text where !text.isEmpty {
            filteredRecords = records.filter({ $0.name.rangeOfString(text, options: .CaseInsensitiveSearch, range: nil, locale: nil) != nil })
        } else {
            filteredRecords = records
        }
    }
}

func ==(lhs: ArrangedAddressBookRecord, rhs: ArrangedAddressBookRecord) -> Bool {
    return lhs.user == rhs.user || lhs.phoneNumbers == rhs.phoneNumbers
}

final class ArrangedAddressBookRecord: Hashable {
    var added = false
    let name: String
    let avatar: Asset?
    let user: User?
    let phoneNumbers: [AddressBookPhoneNumber]
    
    var hashValue: Int = 0
    
    init(name: String, avatar: Asset?, user: User?, phoneNumbers: [AddressBookPhoneNumber]) {
        self.name = name
        self.avatar = avatar
        self.user = user
        self.phoneNumbers = phoneNumbers
        hashValue = user?.hashValue ?? phoneNumbers.first?.hashValue ?? 0
    }
    lazy var infoString: String? = {
        if let user = self.user where user.valid {
            guard let phoneNumber = self.phoneNumbers.last else { return nil }
            if phoneNumber.activated {
                return "signup_status".ls
            } else {
                return "sign_up_pending".ls
            }
        } else {
            return "invite_me_to_meWrap".ls
        }
    }()
    lazy var phones: String = {
        if let user = self.user where user.valid {
            return user.phones
        } else {
            return self.phoneNumbers.reduce("", combine: {
                return $0.isEmpty ? ($0 + $1.phone) : ($0 + "\n" + $1.phone)
            })
        }
    }()
    lazy var numberOfPhones: Int = {
        if let user = self.user where user.valid {
            return user.devices.filter({ $0.phone != nil }).count
        } else {
            return self.phoneNumbers.count
        }
    }()
}

final class ArrangedAddressBook {
    
    let wrap: Wrap?
    var records = [ArrangedAddressBookRecord]()
    var selectedPhoneNumbers = [ArrangedAddressBookRecord: [AddressBookPhoneNumber]]()
    
    convenience init(wrap: Wrap?, records: [AddressBookRecord]) {
        self.init(wrap: wrap)
        var invitees: [Invitee] = FetchRequest<Invitee>().execute()
        for invitee in invitees.reverse() {
            if invitee.wrap == nil {
                invitees.remove(invitee)
                EntryContext.sharedContext.deleteEntry(invitee)
            }
        }
        for record in records {
            addRecord(record, wrap: wrap, invitees: invitees)
        }
        sort()
    }
    
    init(wrap: Wrap?) {
        self.wrap = wrap
    }
    
    private func checkIfAdded(record: ArrangedAddressBookRecord, wrap: Wrap) -> Bool {
        if let user = record.user {
            if wrap.contributors.contains(user) {
                return true
            } else if wrap.invitees.contains({ $0.user == user }) {
                return true
            }
        } else {
            for phoneNumber in record.phoneNumbers {
                if wrap.invitees.contains({ $0.phones.contains(phoneNumber.phone) }) {
                    return true
                }
            }
        }
        return false
    }
    
    func addRecord(record: AddressBookRecord, wrap: Wrap?, invitees: [Invitee]) {
        var phoneNumbers = [AddressBookPhoneNumber]()
        for phoneNumber in record.phoneNumbers {
            if invitees.contains({ $0.phones.contains(phoneNumber.phone) }) {
                let newRecord = ArrangedAddressBookRecord(name: record.name, avatar: record.avatar, user: nil, phoneNumbers: [phoneNumber])
                if let wrap = wrap {
                    newRecord.added = checkIfAdded(newRecord, wrap: wrap)
                }
                records.append(newRecord)
            } else if let user = phoneNumber.user {
                let newRecord = ArrangedAddressBookRecord(name: user.name ?? record.name, avatar: user.avatar, user: user, phoneNumbers: [phoneNumber])
                if let wrap = wrap {
                    newRecord.added = checkIfAdded(newRecord, wrap: wrap)
                }
                records.append(newRecord)
            } else {
                phoneNumbers.append(phoneNumber)
            }
        }
        if phoneNumbers.count != 0 {
            let newRecord = ArrangedAddressBookRecord(name: record.name, avatar: record.avatar, user: nil, phoneNumbers: phoneNumbers)
            records.append(newRecord)
        }
    }
    
    func sort() {
        records.sortInPlace { $0.name < $1.name }
    }
    
    func clearSelection() {
        selectedPhoneNumbers.removeAll()
    }
    
    func selectionIsEmpty() -> Bool {
        return !selectedPhoneNumbers.contains({ (_, phoneNumbers) -> Bool in
            !phoneNumbers.isEmpty
        })
    }
    
    func selectPhoneNumber(record: ArrangedAddressBookRecord, phoneNumber: AddressBookPhoneNumber) {
        if var phoneNumbers = selectedPhoneNumbers[record] {
            if phoneNumbers.contains(phoneNumber) {
                phoneNumbers.remove(phoneNumber)
            } else {
                phoneNumbers.append(phoneNumber)
            }
            if phoneNumbers.isEmpty {
                selectedPhoneNumbers[record] = nil
            } else {
                selectedPhoneNumbers[record] = phoneNumbers
            }
        } else {
            selectedPhoneNumbers[record] = [phoneNumber]
        }
    }
}
