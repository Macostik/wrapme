//
//  Notifier.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

func ==(lhs: NotifyReceiverWrapper, rhs: NotifyReceiverWrapper) -> Bool {
    return lhs.receiver == rhs.receiver
}

class NotifyReceiverWrapper: Hashable {
    weak var receiver: NSObject?
    init(receiver: NSObject?) {
        self.receiver = receiver
    }
    
    var hashValue: Int {
        return receiver?.hashValue ?? 0
    }
}

class Notifier: NSObject {
    
    var receivers = Set<NotifyReceiverWrapper>()
        
    func addReceiver(receiver: NSObject?) {
        if let receiver = receiver {
            receivers.insert(NotifyReceiverWrapper(receiver: receiver))
        }
    }
    
    func removeReceiver(receiver: NSObject?) {
        if let index = receivers.indexOf({ $0.receiver == receiver }) {
            receivers.removeAtIndex(index)
        }
    }
    
    func notify(enumerator: (receiver: AnyObject) -> Void) {
        for wrapper in self.receivers {
            if let receiver = wrapper.receiver {
                enumerator(receiver: receiver)
            }
        }
    }
}