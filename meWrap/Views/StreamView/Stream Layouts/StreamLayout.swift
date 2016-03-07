//
//  StreamLayout.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

protocol StreamLayoutDelegate: StreamViewDelegate {
    func streamView(streamView:StreamView, offsetForLayout:StreamLayout) -> CGFloat
}

extension StreamLayoutDelegate {
    func streamView(streamView:StreamView, offsetForLayout:StreamLayout) -> CGFloat { return 0 }
}

class StreamLayout {
    
    weak var streamView: StreamView?
    
    var horizontal: Bool
    
    init(streamView: StreamView, horizontal: Bool = false) {
        self.streamView = streamView
        self.horizontal = horizontal
    }
    
    var offset: CGFloat = 0
    
    var finalized = false
    
    func prepareLayout() {
        finalized = false
        if let streamView = streamView, let delegate = streamView.delegate as? StreamLayoutDelegate {
            offset = delegate.streamView(streamView, offsetForLayout: self)
        } else {
            offset = 0
        }
    }
    
    func layoutItem(item: StreamItem) {
        if let streamView = streamView {
            if (horizontal) {
                layoutItemHorizontally(item, streamView: streamView)
            } else {
                layoutItemVertically(item, streamView: streamView)
            }
        }
    }
    
    func layoutItemHorizontally(item: StreamItem, streamView: StreamView) {
        var current = item
        var next: StreamItem? = current
        while let item = next {
            item.frame = horizontalFrameForItem(item, streamView: streamView)
            next = item.next
            current = item
        }
        streamView.changeContentSize(CGSizeMake(current.frame.maxX, streamView.frame.height))
    }
    
    func layoutItemVertically(item: StreamItem, streamView: StreamView) {
        var current = item
        var next: StreamItem? = current
        while let item = next {
            item.frame = verticalFrameForItem(item, streamView: streamView)
            next = item.next
            current = item
        }
        streamView.changeContentSize(CGSizeMake(streamView.frame.width, current.frame.maxY))
    }
    
    func horizontalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let size = item.size
        let insets = item.insets
        let offset = item.previous?.frame.maxX ?? self.offset
        return CGRectMake(offset + insets.origin.x, insets.origin.y, size + insets.width, streamView.frame.height - insets.origin.y - insets.height)
    }
    
    func verticalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
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