//
//  AddressBook.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AddressBook

@objc protocol AddressBookNoifying {
    optional func addressBook(addressBook: AddressBook, didUpdateCachedRecords cachedRecords: [AddressBookRecord]?)
}

func addressBookChanged(addessBook: ABAddressBookRef!, info: CFDictionary!, context: UnsafeMutablePointer<Void>) {
    if let _addressBook = ABAddressBookCreateWithOptions(nil, nil)?.takeUnretainedValue() {
        AddressBook.sharedAddressBook.ABAddressBook = _addressBook
    } else {
        AddressBook.sharedAddressBook.ABAddressBook = addessBook
    }
    AddressBook.sharedAddressBook.enqueueSelector(#selector(AddressBook.updateCachedRecords), delay: 0.0)
}

class AddressBook: Notifier {
    
    private var ABAddressBook: ABAddressBookRef?
    
    static var sharedAddressBook = AddressBook()
    
    private var runQueue = RunQueue(limit: 1)
    
    var cachedRecords: [AddressBookRecord]? {
        didSet {
            notify { $0.addressBook?(self, didUpdateCachedRecords: cachedRecords) }
        }
    }
    
    private func validCachedRecords() -> [AddressBookRecord]? {
        if let records = cachedRecords {
            if records.contains({ $0.phoneNumbers.contains({ !($0.user?.valid ?? true) })}) {
                cachedRecords = nil
                return nil
            } else {
                return records
            }
        } else {
            return nil
        }
    }
    
    func cachedRecords(success: [AddressBookRecord] -> Void, failure: FailureBlock?) -> Bool {
        if let records = validCachedRecords() {
            success(records)
            return true
        } else {
            
            runQueue.run { (finish) -> Void in
                
                let _failure: FailureBlock = { error in
                    failure?(error)
                    finish()
                }
                
                self.addressBook({ (ab) -> Void in
                    self.records(ab, success: { (records) -> Void in
                        success(records)
                        finish()
                        }, failure: _failure)
                    }, failure: _failure)
            }
            return false
        }
    }
    
    private func records(addressBook: ABAddressBookRef, success: [AddressBookRecord] -> Void, failure: FailureBlock?) {
        Dispatch.defaultQueue.async { () -> Void in
            do {
                let records = try self.contacts(addressBook)
                Dispatch.mainQueue.async {
                    APIRequest.contributorsFromRecords(records)?.send({ (object) -> Void in
                        if let records = object as? [AddressBookRecord] {
                            self.cachedRecords = records
                            success(records)
                        } else {
                            failure?(NSError(message: "no_contacts".ls))
                        }
                        }, failure: failure)
                }
            } catch let error as NSError {
                Dispatch.mainQueue.async { failure?(error) }
            }
        }
    }
    
    private func contacts(addressBook: ABAddressBookRef) throws -> [AddressBookRecord] {
        let count = ABAddressBookGetPersonCount(addressBook)
        if (count > 0) {
            let contacts = ABAddressBookCopyArrayOfAllPeople(addressBook).takeUnretainedValue() as [ABRecordRef]
            var records = [AddressBookRecord]()
            for i in 0..<count {
                if let contact = AddressBookRecord(ABRecord: contacts[i]) {
                    records.append(contact)
                }
            }
            if records.count > 0 {
                return records
            } else {
                throw NSError(message: "no_contacts_with_phone_number".ls)
            }
        } else {
            throw NSError(message: "no_contacts".ls)
        }
    }
    
    private func addressBook(success: ABAddressBookRef -> Void, failure: FailureBlock?) {
        if let addressBook = ABAddressBook {
            success(addressBook)
        } else {
            if let addressBook = ABAddressBookCreateWithOptions(nil, nil)?.takeUnretainedValue() {
                ABAddressBookRequestAccessWithCompletion(addressBook, { (granted, error) -> Void in
                    Dispatch.mainQueue.async { () -> Void in
                        if let error = error as NSError? {
                            failure?(error)
                        } else if granted {
                            self.ABAddressBook = addressBook
                            success(addressBook)
                        } else {
                            failure?(NSError(message: "no_access_to_contacts".ls))
                        }
                    }
                })
            } else {
                failure?(NSError(message: "no_access_to_contacts".ls))
            }
        }
    }
    
    func getABAddressBook() -> ABAddressBookRef? {
        return ABAddressBook
    }
    
    func updateCachedRecords() {
        runQueue.run { (finish) -> Void in
            self.addressBook({ (addressBook) -> Void in
                self.records(addressBook, success: { (_) -> Void in
                    finish()
                    }, failure: { (error) -> Void in
                        finish()
                })
                }) { (error) -> Void in
                    if let error = error where error.isNetworkError {
                        Network.sharedNetwork.addReceiver(self)
                    }
                    finish()
            }
        }
    }
    
    func beginCaching() {
        runQueue.run { (finish) -> Void in
            self.addressBook({ (addressBook) -> Void in
                self.records(addressBook, success: { (_) -> Void in
                    ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, nil)
                    finish()
                    }, failure: { (error) -> Void in
                        finish()
                })
                }) { (error) -> Void in
                    finish()
            }
        }
    }
    
    func endCaching() {
        runQueue.run { (finish) -> Void in
            self.addressBook({ (addressBook) -> Void in
                ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, nil)
                finish()
                }) { (error) -> Void in
                    finish()
            }
        }
    }
}

extension AddressBook: NetworkNotifying {
    func networkDidChangeReachability(network: Network) {
        if network.reachable {
            updateCachedRecords()
            network.removeReceiver(self)
        }
    }
}
