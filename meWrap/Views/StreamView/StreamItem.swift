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
    
    var entry: AnyObject?
    
    var layoutInfo: Dictionary<String,AnyObject>?
    
    weak var metrics: StreamMetrics?
    
    weak var view: StreamReusableView? {
        didSet {
            if let view = self.view {
                view.selected = self.selected
            }
        }
    }
    
    var selected: Bool = false {
        didSet {
            if let view = self.view {
                view.selected = self.selected
            }
        }
    }
    
    weak var previous: StreamItem?
    
    weak var next: StreamItem?
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
