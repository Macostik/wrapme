//
//  StreamItem.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit


class StreamItem {
    
    var frame = CGRectZero
    
    var visible = false
    
    var position: StreamPosition
    
    var metrics: StreamMetrics
    
    var column: Int = 0
    
    var entryBlock: (StreamItem -> AnyObject?)?
    
    init(metrics: StreamMetrics, position: StreamPosition) {
        self.metrics = metrics
        self.position = position
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

func ==(lhs: StreamPosition, rhs: StreamPosition) -> Bool {
    return lhs.section == rhs.section && lhs.index == rhs.index
}

struct StreamPosition: Equatable {
    let section: Int
    let index: Int
    static let zero = StreamPosition(section: 0, index: 0)
}
