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
    
    static func presentEntry(entry: Entry, completionHandler: (() -> ())? = nil) {
        AuthorizedExecutor.execute { [weak entry] _ in
            if let entry = entry {
                NotificationEntryPresenter.presentEntryWithPermission(entry, animated:false, completionHandler: completionHandler)
            } else {
                completionHandler?()
            }
        }
    }
    
    static func shareContent(items: [[String:String]]) {
        AuthorizedExecutor.execute {
            UINavigationController.main.dismissViewControllerAnimated(false, completion: nil)
            let navigationController = UINavigationController()
            let wrapListViewController = Storyboard.WrapList.instantiate({ $0.items = items })
            navigationController.navigationBarHidden = true
            navigationController.viewControllers = [wrapListViewController]
                
            UINavigationController.main.presentViewController(navigationController, animated: false, completion: nil)
        }
    }
}