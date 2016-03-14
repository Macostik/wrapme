//
//  EventualEntryPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

struct AuthorizedExecutor {
    
    private static var block: (Void -> Void)?
    
    static var authorized = false {
        willSet {
            if let block = block where newValue {
                block()
                AuthorizedExecutor.block = nil
            }
        }
    }
    
    static func execute(block: Void -> Void) {
        if authorized {
            block()
        } else {
            AuthorizedExecutor.block = block
        }
    }
}

extension AuthorizedExecutor {
    
    static func presentEntry(entryReference: [String:String]) {
        AuthorizedExecutor.execute {
            if let entry = Entry.deserializeReference(entryReference) {
                NotificationEntryPresenter.presentEntryRequestingAuthorization(entry, animated:false)
            }
        }
    }
    
    static func shareContent() {
        AuthorizedExecutor.execute {
            UINavigationController.main()?.dismissViewControllerAnimated(false, completion: nil)
            UINavigationController.main()?.pushViewController(Storyboard.WrapList.instantiate(), animated: false)
        }
    }
}