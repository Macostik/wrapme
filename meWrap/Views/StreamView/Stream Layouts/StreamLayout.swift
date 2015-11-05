//
//  StreamLayout.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

@objc protocol StreamLayoutDelegate: StreamViewDelegate {

    optional func streamView(streamView:StreamView, offsetForLayout:StreamLayout) -> CGFloat

}

class StreamLayout: NSObject {
    
    weak var streamView: StreamView?
    
    @IBInspectable var horizontal: Bool = false
    
    convenience init(horizontal: Bool) {
        self.init()
        self.horizontal = horizontal
    }
    
    var offset: CGFloat = 0
    
    var finalized = false
    
    func prepareLayout() {
        finalized = false
        if let streamView = streamView, let delegate = streamView.delegate as? StreamLayoutDelegate {
            offset = delegate.streamView?(streamView, offsetForLayout: self) ?? 0
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
        if let metrics = item.metrics, position = item.position {
            let size = metrics.sizeAt(position, metrics)
            let insets = metrics.insetsAt(position, metrics)
            var offset = self.offset
            if let previous = item.previous {
                offset = previous.frame.maxX
            }
            return CGRectMake(offset + insets.origin.x, insets.origin.y, size + insets.width, streamView.frame.height - insets.origin.y - insets.height)
        }
        return CGRectZero
    }
    
    func verticalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        if let metrics = item.metrics, position = item.position {
            let size = metrics.sizeAt(position, metrics)
            let insets = metrics.insetsAt(position, metrics)
            var offset = self.offset
            if let previous = item.previous {
                offset = previous.frame.maxY
            }
            return CGRectMake(insets.origin.x, offset + insets.origin.y, streamView.frame.width - insets.origin.x - insets.width, size + insets.height)
        }
        return CGRectZero
    }
    
    func prepareForNextSection() {
    
    }
    
    func finalizeLayout() {
        prepareForNextSection()
        finalized = true
    }
}