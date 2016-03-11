//
//  EventualEntryPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

struct AuthorizedExecutor {
    
    private struct Execution { var block: Void -> Void }
    
    private static var executions = [Execution]()
    
    static var authorized = false {
        willSet {
            if newValue && !executions.isEmpty {
                executions.all { $0.block() }
                executions.removeAll()
            }
        }
    }
    
    static func execute(block: Void -> Void) {
        if authorized {
            block()
        } else {
            executions.append(Execution(block: block))
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
            UINavigationController.main()?.pushViewController(Storyboard.WrapList.instantiate(), animated: false)
        }
    }
}