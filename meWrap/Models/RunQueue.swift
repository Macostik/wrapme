//
//  RunQueue.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/7/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

typealias RunBlock = (finish: Void -> Void) -> Void

final class RunQueue {
    
    static let entryFetchQueue = RunQueue(limit: 3)
    
    static let fetchQueue = RunQueue(limit: 1)
    
    private var blocks = [RunBlock]()
    
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
    
    private func _run(block: RunBlock) {
        block(finish: {
            if let block = self.blocks.first {
                _ = self.blocks.removeFirst()
                self._run(block)
            } else {
                self.executions = self.executions - 1
            }
        })
    }
    
    func run(block: RunBlock) {
        if limit == 0 || executions < limit {
            executions = executions + 1
            _run(block)
        } else {
            blocks.append(block)
        }
    }
    
    func cancelAll() {
        blocks.removeAll()
    }
}
