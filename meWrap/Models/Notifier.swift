//
//  Notifier.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

private struct NotifierReceiver<T> {
    weak var owner: AnyObject?
    var block: T -> ()
}

class Notifier<T> {
    
    private var receivers = [NotifierReceiver<T>]()
    
    func subscribe(owner: AnyObject, block: (value: T) -> ()) {
        receivers = receivers.filter({ $0.owner != nil })
        receivers.append(NotifierReceiver(owner: owner, block: block))
    }
    
    func unsubscribe(owner: AnyObject) {
        receivers = receivers.filter({ $0.owner !== owner })
    }
    
    func notify(value: T) {
        for receiver in receivers where receiver.owner != nil {
            receiver.block(value)
        }
    }
}
