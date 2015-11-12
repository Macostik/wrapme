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
    
    var frame: CGRect = CGRectZero
    
    var visible: Bool = false
    
    var position: StreamPosition?
    
    var column: Int = 0
    
    var entryBlock: (StreamItem -> AnyObject?)?
    
    private var _entry: AnyObject?
    var entry: AnyObject? {
        set {
            _entry = newValue
        }
        get {
            if _entry == nil {
                _entry = entryBlock?(self)
            }
            return _entry
        }
    }
    
    weak var metrics: StreamMetrics?
    
    weak var view: StreamReusableView? {
        didSet {
            if let view = view {
                view.selected = selected
            }
        }
    }
    
    var selected: Bool = false {
        didSet {
            if let view = view {
                view.selected = selected
            }
        }
    }
    
    weak var previous: StreamItem?
    
    var next: StreamItem?
}

class StreamPosition: NSObject {
    let section: UInt
    let index: UInt
    init(section: UInt, index: UInt) {
        self.section = section
        self.index = index
    }
    func isEqualToPosition(position: StreamPosition) -> Bool {
        return self.section == position.section && self.index == position.index
    }
}
