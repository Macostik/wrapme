//
//  StreamItem.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

final class StreamItem {
    
    var frame = CGRectZero
    var visible = false
    var position: StreamPosition
    var metrics: StreamMetrics
    var entryBlock: (StreamItem -> AnyObject?)?
    
    init(metrics: StreamMetrics, position: StreamPosition) {
        self.metrics = metrics
        self.position = position
        hidden = metrics.hidden
        size = metrics.size
        insets = metrics.insets
        ratio = metrics.ratio
    }
    
    lazy var entry: AnyObject? = self.entryBlock?(self)
    
    weak var view: StreamReusableView? {
        willSet { newValue?.selected = selected }
    }
    
    var selected: Bool = false {
        willSet { view?.selected = newValue }
    }
    
    weak var previous: StreamItem?
    weak var next: StreamItem?
    
    var column: Int = 0
    var hidden: Bool = false
    var size: CGFloat = 0
    var insets: CGRect = CGRectZero
    var ratio: CGFloat = 0
}

func ==(lhs: StreamPosition, rhs: StreamPosition) -> Bool {
    return lhs.section == rhs.section && lhs.index == rhs.index
}

struct StreamPosition: Equatable {
    let section: Int
    let index: Int
    static let zero = StreamPosition(section: 0, index: 0)
}
