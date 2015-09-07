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
    
    var index: StreamIndex?
    
    weak var metrics: StreamMetrics?
    
    weak var view: StreamReusableView? {
        didSet {
            view!.selected = selected
        }
    }
    
    var selected: Bool = false {
        didSet {
            if view != nil {
                view!.selected = selected
            }
        }
    }
}


class StreamIndex: NSObject, NSCopying {
    var value: Int = 0
    
    var next: StreamIndex?
    
    var section: Int {
        return value
    }
    
    var item: Int {
        if let next = self.next {
            return next.value
        } else {
            return 0
        }
    }
    
    init(index: Int) {
        value = index
        super.init()
    }
    
    func add(index: Int) -> StreamIndex {
        if next != nil {
            next?.add(index)
        } else {
            next = StreamIndex(index: index)
        }
        return self;
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        var newInstance = self.dynamicType.init(index: value)
        if let next = self.next {
            newInstance.next = next.copy() as? StreamIndex
        }
        return newInstance;
    }
}