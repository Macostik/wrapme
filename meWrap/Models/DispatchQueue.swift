//
//  DispatchQueue.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class DispatchQueue: NSObject {
    
    static let mainQueue = DispatchQueue(queue: dispatch_get_main_queue())
    
    static let defaultQueue = DispatchQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    
    static let backgroundQueue = DispatchQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
    
    private var queue: dispatch_queue_t
    
    required init(queue: dispatch_queue_t) {
        self.queue = queue
    }
    
    func run(block: (Void -> Void)?) {
        if let block = block {
            dispatch_async(queue, block)
        }
    }
    
    private static let delayMultiplier = Float(NSEC_PER_SEC)
    
    func runAfter(delay: Float, block: (Void -> Void)?) {
        if let block = block {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * DispatchQueue.delayMultiplier)), queue, block)
        }
    }
    
    func runAfterAsap(block: Void -> Void) {
        runAfter(0, block: block)
    }
    
    func runGettingObject(block: (Void -> AnyObject?)?, completion: (AnyObject? -> Void)?) {
        run { () -> Void in
            let object = block?()
            DispatchQueue.mainQueue.run({ () -> Void in
                completion?(object)
            })
        }
    }
}
