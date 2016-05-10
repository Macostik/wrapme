//
//  Dispatch.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

struct Dispatch {
    
    static let mainQueue = Dispatch(queue: dispatch_get_main_queue())
    
    static let defaultQueue = Dispatch(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    
    static let backgroundQueue = Dispatch(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
    
    private var queue: dispatch_queue_t
    
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
    
    static func sleep<T>(@noescape block: (awake: T? -> ()) -> ()) -> T? {
        let semaphore = dispatch_semaphore_create(0)
        var value: T?
        block(awake: {
            value = $0
            dispatch_semaphore_signal(semaphore)
        })
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return value
    }
}

final class DispatchTask {
    
    var block: (Void -> Void)?
    
    init(_ delay: Float = 0, _ block: Void -> Void) {
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
