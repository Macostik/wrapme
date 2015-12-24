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
            return pn1?.name > pn2?.name
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
            for _phoneNumber in record.phoneNumbers where _phoneNumber.equals(phoneNumber) {
                return _phoneNumber
            }
        }
        return nil
    }
}
