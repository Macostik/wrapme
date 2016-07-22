//
//  AddressBook.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AddressBook

func addressBookChanged(addessBook: ABAddressBookRef!, info: CFDictionary!, context: UnsafeMutablePointer<Void>) {
    if let _addressBook = ABAddressBookCreateWithOptions(nil, nil)?.takeUnretainedValue() {
        AddressBook.sharedAddressBook.ABAddressBook = _addressBook
    } else {
        AddressBook.sharedAddressBook.ABAddressBook = addessBook
    }
    AddressBook.sharedAddressBook.updateCachedRecords()
}

class AddressBook: BlockNotifier<[AddressBookRecord]> {
    
    private var ABAddressBook: ABAddressBookRef?
    
    static var sharedAddressBook = AddressBook()
    
    private var runQueue = RunQueue(limit: 1)
    
    var cachedRecords: [AddressBookRecord]? {
        didSet {
            if let cachedRecords = cachedRecords {
                notify(cachedRecords)
            }
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
    
    func cachedRecords(success: [AddressBookRecord] -> (), failure: ([AddressBookRecord], NSError?) -> ()) -> Bool {
        if let records = validCachedRecords() {
            success(records)
            return true
        } else {
            records(success, failure: failure)
            return false
        }
    }
    
    func records(success: [AddressBookRecord] -> (), failure: ([AddressBookRecord], NSError?) -> ()) {
        runQueue.run { finish in
            
            let _failure: (([AddressBookRecord], NSError?) -> ()) = { records, error in
                failure(records, error)
                finish()
            }
            
            self.addressBook({ ab in
                self.records(ab, success: { records in
                    success(records)
                    finish()
                    }, failure: _failure)
                }, failure: { error in
                    _failure([], error)
            })
        }
    }
    
    private func records(addressBook: ABAddressBookRef, success: [AddressBookRecord] -> (), failure: ([AddressBookRecord], NSError?) -> ()) {
        Dispatch.defaultQueue.async {
            do {
                let records = try self.contacts(addressBook)
                Dispatch.mainQueue.async {
                    API.contributorsFromRecords(records).send({ records in
                        self.cachedRecords = records
                        success(records)
                        }, failure: { error in
                            failure(records, error)
                    })
                }
            } catch let error as NSError {
                Dispatch.mainQueue.async { failure([], error) }
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
    
    private func addressBook(success: ABAddressBookRef -> (), failure: FailureBlock?) {
        if let addressBook = ABAddressBook {
            success(addressBook)
        } else {
            if let addressBook = ABAddressBookCreateWithOptions(nil, nil)?.takeUnretainedValue() {
                ABAddressBookRequestAccessWithCompletion(addressBook, { granted, error in
                    Dispatch.mainQueue.async {
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
    
    private var updatingCachedRecords = false
    
    func updateCachedRecords() {
        
        guard !updatingCachedRecords else { return }
        updatingCachedRecords = true
        
        runQueue.run { [unowned self] finish in
            self.addressBook({ addressBook in
                self.records(addressBook, success: { _ in
                    self.updatingCachedRecords = false
                    finish()
                    }, failure: { records, error in
                        if let error = error where error.isNetworkError {
                            Network.network.subscribe(self, block: { reachable in
                                if reachable {
                                    self.updateCachedRecords()
                                    Network.network.unsubscribe(self)
                                }
                            })
                        }
                        self.updatingCachedRecords = false
                        finish()
                })
                }) { error in
                    self.updatingCachedRecords = false
                    finish()
            }
        }
    }
    
    func beginCaching() {
        runQueue.run { finish in
            self.addressBook({ addressBook in
                self.records(addressBook, success: { _ in
                    ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, nil)
                    finish()
                    }, failure: { _ in
                        finish()
                })
                }) { _ in
                    finish()
            }
        }
    }
    
    func endCaching() {
        runQueue.run { finish in
            self.addressBook({ addressBook in
                ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, nil)
                finish()
                }) { _ in
                    finish()
            }
        }
    }
}
