//
//  RunQueue.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/7/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class RunQueue: NSObject {
    
    static var entryFetchQueue = RunQueue(limit: 3)
    
    static var fetchQueue = RunQueue(limit: 1)
        
    static var uploadCandiesQueue = RunQueue(limit: 1)
    
    private struct Block {
        var block: (finish: Void -> Void) -> Void
    }
    
    private var blocks = [Block]()
    
    private var executions = 0 {
        didSet {
            if executions == 0 && oldValue > 0 {
                didFinish?()
            } else if oldValue == 0 && executions > 0 {
                didStart?()
            }
        }
    }
    
    var isExecuting: Bool {
        return executions > 0
    }
    
    var didStart: (Void -> Void)?
    
    var didFinish: (Void -> Void)?
    
    var limit = 0
    
    convenience init(limit: Int) {
        self.init()
        self.limit = limit
    }
    
    private func _run(block: (finish: Void -> Void) -> Void) {
        block(finish: {
            if let block = self.blocks.first {
                self.blocks.removeFirst()
                self._run(block.block)
            } else {
                self.executions = self.executions - 1
            }
        })
    }
    
    func run(block: (finish: Void -> Void) -> Void) {
        if limit == 0 || executions < limit {
            executions = executions + 1
            _run(block)
        } else {
            blocks.append(Block(block: block))
        }
    }
    
    func cancelAll() {
        blocks.removeAll()
    }
}
