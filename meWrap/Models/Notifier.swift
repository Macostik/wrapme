//
//  Notifier.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

func ==(lhs: NotifyReceiverWrapper, rhs: NotifyReceiverWrapper) -> Bool {
    return lhs.receiver === rhs.receiver
}

struct NotifyReceiverWrapper: Equatable {
    weak var receiver: AnyObject?
}

class Notifier: NSObject {
    
    internal var receivers = [NotifyReceiverWrapper]()
        
    func addReceiver(receiver: AnyObject?) {
        guard let receiver = receiver else { return }
        receivers.append(NotifyReceiverWrapper(receiver: receiver))
    }
    
    func insertReceiver(receiver: AnyObject?) {
        guard let receiver = receiver else { return }
        receivers.insert(NotifyReceiverWrapper(receiver: receiver), atIndex: 0)
    }
    
    func removeReceiver(receiver: AnyObject?) {
        guard let receiver = receiver else { return }
        if let index = receivers.indexOf({ $0.receiver === receiver }) {
            receivers.removeAtIndex(index)
        }
    }
    
    func notify(@noescape enumerator: (receiver: AnyObject) -> Void) {
        var emptyWrappers = [NotifyReceiverWrapper]()
        for wrapper in receivers {
            if let receiver = wrapper.receiver {
                enumerator(receiver: receiver)
            } else {
                emptyWrappers.append(wrapper)
            }
        }
        for wrapper in emptyWrappers {
            receivers.remove(wrapper)
        }
    }
}

private struct BlockNotifierReceiver<T> {
    weak var owner: AnyObject?
    var block: T -> ()
}

class BlockNotifier<T> {
    
    private var receivers = [BlockNotifierReceiver<T>]()
    
    func subscribe(owner: AnyObject, block: (value: T) -> ()) {
        receivers = receivers.filter({ $0.owner != nil })
        receivers.append(BlockNotifierReceiver(owner: owner, block: block))
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
