//
//  EventualEntryPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class EventualEntryPresenter: NSObject {
    
    typealias EntryReference = [String:String]
    
    var entryReference: EntryReference?
    
    var presetingExtensionBlock: (EntryReference -> Void) = { reference in
        Storyboard.WrapList.instantiate({
            $0.sharePath = reference["path"]
            UINavigationController.main()?.pushViewController($0, animated: false)
        })
    }
    
    var isLoaded = false {
        didSet {
            if let entryReference = entryReference where oldValue != isLoaded && isLoaded == true {
                if !presentEntry(entryReference) {
                    presetingExtensionBlock(entryReference)
                }
                self.entryReference = nil
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
    
    func presentExtension(entryReference: [String:String]) -> Bool {
        if isLoaded {
            presetingExtensionBlock(entryReference)
            return true
        } else {
            self.entryReference = entryReference
            return false
        }
    }
}