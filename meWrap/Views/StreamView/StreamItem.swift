//
//  StreamItem.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit


class StreamItem: NSObject {
    
    var frame = CGRectZero
    
    var visible = false
    
    var position: StreamPosition
    
    var metrics: StreamMetrics
    
    var column: Int = 0
    
    var entryBlock: (StreamItem -> AnyObject?)?
    
    required init(metrics: StreamMetrics, position: StreamPosition) {
        self.metrics = metrics
        self.position = position
        super.init()
    }
    
    private var _entry: AnyObject?
    var entry: AnyObject? {
        set { _entry = newValue }
        get {
            if _entry == nil {
                _entry = entryBlock?(self)
            }
            return _entry
        }
    }
    
    weak var view: StreamReusableView? {
        didSet { view?.selected = selected }
    }
    
    var selected: Bool = false {
        didSet { view?.selected = selected }
    }
    
    weak var previous: StreamItem?
    
    var next: StreamItem?
}

class StreamPosition: NSObject {
    let section: Int
    let index: Int
    init(section: Int, index: Int) {
        self.section = section
        self.index = index
    }
    func isEqualToPosition(position: StreamPosition) -> Bool {
        return self.section == position.section && self.index == position.index
    }
}
