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
        if let streamView = self.streamView, let delegate = streamView.delegate as? StreamLayoutDelegate {
            if let offset = delegate.streamView?(streamView, offsetForLayout: self) {
                self.offset = offset
            } else {
                self.offset = 0
            }
        } else {
            self.offset = 0
        }
    }
    
    func layoutItem(item: StreamItem) {
        if let streamView = self.streamView {
            if (self.horizontal) {
                layoutItemHorizontally(item, streamView: streamView)
            } else {
                layoutItemVertically(item, streamView: streamView)
            }
        }
    }
    
    func layoutItemHorizontally(item: StreamItem, streamView: StreamView) {
        var next: StreamItem? = item
        while next != nil {
            if let item = next {
                item.frame = horizontalFrameForItem(item, streamView: streamView)
                if item.next != nil {
                    next = item.next
                } else {
                    streamView.changeContentSize(CGSizeMake(CGRectGetMaxX(item.frame), streamView.frame.size.height))
                    next = nil
                }
            }
        }
    }
    
    func layoutItemVertically(item: StreamItem, streamView: StreamView) {
        var next: StreamItem? = item
        while next != nil {
            if let item = next {
                item.frame = verticalFrameForItem(item, streamView: streamView)
                if item.next != nil {
                    next = item.next
                } else {
                    streamView.changeContentSize(CGSizeMake(streamView.frame.size.width, CGRectGetMaxY(item.frame)))
                    next = nil
                }
            }
        }
    }
    
    func horizontalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        if let metrics = item.metrics, position = item.position {
            let size = metrics.sizeAt(position, metrics)
            let insets = metrics.insetsAt(position, metrics)
            var offset = self.offset
            if let previous = item.previous {
                offset = CGRectGetMaxX(previous.frame)
            }
            return CGRectMake(offset + insets.origin.x, insets.origin.y, size + insets.size.width, streamView.frame.size.height - insets.origin.y - insets.size.height)
        }
        return CGRectZero
    }
    
    func verticalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        if let metrics = item.metrics, position = item.position {
            let size = metrics.sizeAt(position, metrics)
            let insets = metrics.insetsAt(position, metrics)
            var offset = self.offset
            if let previous = item.previous {
                offset = CGRectGetMaxY(previous.frame)
            }
            return CGRectMake(insets.origin.x, offset + insets.origin.y, streamView.frame.size.width - insets.origin.x - insets.size.width, size + insets.size.height)
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