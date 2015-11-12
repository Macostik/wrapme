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

class Notifier: NSObject {
    
    static var PriorityHigh = -1
    static var PriorityMedium = 0
    static var PriorityLow = 1
    
    private var receivers: NSHashTable = NSHashTable.weakObjectsHashTable()
    
    var prioritize: Bool = false
    
    func addReceiver(receiver: AnyObject) {
        if !receivers.containsObject(receiver) {
            if let _ = receiver.notifierPriority?(self) {
                prioritize = true
            }
            receivers.addObject(receiver)
        }
    }
    
    func removeReceiver(receiver: AnyObject) {
        receivers.removeObject(receiver)
    }
    
    func notify(enumerator: AnyObject -> Void) {
        
        var receivers: [AnyObject]?
        if prioritize {
            receivers = self.receivers.allObjects.sort({[unowned self] (r1, r2) -> Bool in
                let first = r1.notifierPriority?(self) ?? Notifier.PriorityMedium
                let second = r2.notifierPriority?(self) ?? Notifier.PriorityMedium
                return first < second
            })
        } else {
            receivers = self.receivers.allObjects
        }
        
        if let receivers = receivers {
            for receiver in receivers {
                enumerator(receiver)
            }
        }
    }
}