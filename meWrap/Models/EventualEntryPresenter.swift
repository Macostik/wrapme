//
//  EventualEntryPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class EventualEntryPresenter: NSObject {
    
    var entryReference: [String:String]?
    
    var isLoaded = false {
        didSet {
            if let entryReference = entryReference where isLoaded {
                presentEntry(entryReference)
            }
        }
    }
    
    static var sharedPresenter = EventualEntryPresenter()
    
    func presentEntry(entryReference: [String:String]) -> Bool {
        if isLoaded {
            if let entry = Entry.deserializeReference(entryReference) {
                NotificationEntryPresenter.presentEntryRequestingAuthorization(entry, animated:false)
                return true
            } else {
                return false
            }
        } else {
            self.entryReference = entryReference
            return false
        }
    }
}