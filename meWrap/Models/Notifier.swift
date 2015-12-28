//
//  Notifier.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

internal class NotifyReceiverWrapper {
    weak var receiver: NSObject?
    init(receiver: NSObject?) {
        self.receiver = receiver
    }
}

class Notifier: NSObject {
    
    internal var receivers = [NotifyReceiverWrapper]()
        
    func addReceiver(receiver: NSObject?) {
        if let receiver = receiver {
            receivers.append(NotifyReceiverWrapper(receiver: receiver))
        }
    }
    
    func removeReceiver(receiver: NSObject?) {
        if let index = receivers.indexOf({ $0.receiver == receiver }) {
            receivers.removeAtIndex(index)
        }
    }
    
    func notify(@noescape enumerator: (receiver: AnyObject) -> Void) {
        receivers = receivers.filter { (wrapper) -> Bool in
            if let receiver = wrapper.receiver {
                enumerator(receiver: receiver)
                return true
            } else {
                return false
            }
        }
    }
}

@objc protocol OrderedNotifierReceiver {
    optional func notifier(notifier: OrderedNotifier, shouldNotifyBeforeReceiver receiver: AnyObject) -> Bool
}

class OrderedNotifier: Notifier {
    override func notify(@noescape enumerator: (receiver: AnyObject) -> Void) {
        var _receivers = [AnyObject]()
        super.notify { _receivers.append($0) }
        _receivers = _receivers.sort({ $0.notifier?(self, shouldNotifyBeforeReceiver: $1) ?? false })
        for receiver in _receivers {
            enumerator(receiver: receiver)
        }
    }
}