//
//  Notifier.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

@objc protocol Notifying {
    optional func notifierPriority(notifier: Notifier) -> Int
}

class NotifyReceiverWrapper: NSObject {
    weak var receiver: AnyObject?
    init(receiver: AnyObject?) {
        self.receiver = receiver
    }
}

class Notifier: NSObject {
    
    static var PriorityHigh = -1
    static var PriorityMedium = 0
    static var PriorityLow = 1
    
    private var receivers = [NotifyReceiverWrapper]()
    
    var prioritize: Bool = false
    
    func containsReceiver(receiver: AnyObject?) -> Bool {
        return receivers.contains { (wrapper) -> Bool in
            return wrapper.receiver === receiver
        }
    }
    
    func addReceiver(receiver: AnyObject?) {
        if let receiver = receiver where !containsReceiver(receiver) {
            if let _ = receiver.notifierPriority?(self) {
                prioritize = true
            }
            receivers.append(NotifyReceiverWrapper(receiver: receiver))
        }
    }
    
    func removeReceiver(receiver: AnyObject?) {
        let index = receivers.indexOf({ (wrapper) -> Bool in
            return wrapper.receiver === receiver
        })
        if let index = index {
            receivers.removeAtIndex(index)
        }
    }
    
    func notify(enumerator: AnyObject -> Void) {
        
        var receivers: [NotifyReceiverWrapper]?
        if prioritize {
            receivers = self.receivers.sort({[unowned self] (r1, r2) -> Bool in
                let first = r1.receiver?.notifierPriority?(self) ?? Notifier.PriorityMedium
                let second = r2.receiver?.notifierPriority?(self) ?? Notifier.PriorityMedium
                return first < second
            })
        } else {
            receivers = self.receivers
        }
        
        if let receivers = receivers {
            for wrapper in receivers {
                if let receiver = wrapper.receiver {
                    enumerator(receiver)
                }
            }
        }
    }
}