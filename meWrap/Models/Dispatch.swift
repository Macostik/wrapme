//
//  Dispatch.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class Dispatch: NSObject {
    
    static let mainQueue = Dispatch(queue: dispatch_get_main_queue())
    
    static let defaultQueue = Dispatch(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    
    static let backgroundQueue = Dispatch(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
    
    private var queue: dispatch_queue_t
    
    required init(queue: dispatch_queue_t) {
        self.queue = queue
    }
    
    func sync(block: (Void -> Void)?) {
        if let block = block {
            dispatch_sync(queue, block)
        }
    }
    
    func async(block: (Void -> Void)?) {
        if let block = block {
            dispatch_async(queue, block)
        }
    }
    
    private static let delayMultiplier = Float(NSEC_PER_SEC)
    
    func after(delay: Float, block: (Void -> Void)?) {
        if let block = block {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Dispatch.delayMultiplier)), queue, block)
        }
    }
    
    func fetch<T>(block: (Void -> T), completion: (T -> Void)) {
        async {
            let object = block()
            Dispatch.mainQueue.async({ completion(object) })
        }
    }
}

class DispatchTask {
    
    var block: (Void -> Void)?
    
    init(delay: Float, block: Void -> Void) {
        self.block = block
        Dispatch.mainQueue.after(delay) { [weak self] () -> Void in
            if let block = self?.block {
                block()
            }
        }
    }
    
    func cancel() {
        block = nil
    }
}
