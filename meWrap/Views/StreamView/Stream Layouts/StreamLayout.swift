//
//  StreamLayout.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

class StreamLayout {
    
    var horizontal: Bool { return false }
    
    var offset: CGFloat = 0
    
    var finalized = false
    
    func prepareLayout(streamView: StreamView) {
        finalized = false
    }
    
    func contentSize(item: StreamItem, streamView: StreamView) -> CGSize {
        if horizontal {
            return CGSizeMake(item.frame.maxX, streamView.frame.height)
        } else {
            return CGSizeMake(streamView.frame.width, item.frame.maxY)
        }
    }
    
    func recursivelyLayoutItem(item: StreamItem, streamView: StreamView) {
        var next: StreamItem? = item
        while let item = next {
            item.frame = frameForItem(item, streamView: streamView)
            next = item.next
        }
    }
    
    func layoutItem(item: StreamItem, streamView: StreamView) {
        item.frame = frameForItem(item, streamView: streamView)
    }
    
    func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let size = item.size
        let insets = item.insets
        let offset = item.previous?.frame.maxY ?? self.offset
        return CGRectMake(insets.origin.x, offset + insets.origin.y, streamView.frame.width - insets.origin.x - insets.width, size + insets.height)
    }
    
    func prepareForNextSection() { }
    
    func finalizeLayout() {
        prepareForNextSection()
        finalized = true
    }
}

class HorizontalStreamLayout: StreamLayout {
    
    override var horizontal: Bool { return true }
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let size = item.size
        let insets = item.insets
        let offset = item.previous?.frame.maxX ?? self.offset
        return CGRectMake(offset + insets.origin.x, insets.origin.y, size + insets.width, streamView.frame.height - insets.origin.y - insets.height)
    }
}