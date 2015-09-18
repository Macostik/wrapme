//
//  GridLayout.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

class SquareGridLayout: StreamLayout {
    
    var numberOfColumns: Int = 1
    var size: CGFloat = 0
    var spacing: CGFloat = 0
    
    override func prepareLayout() {
        if let streamView = self.streamView, let delegate = streamView.delegate as? GridLayoutDelegate {
            if let columns = delegate.streamView?(streamView, layoutNumberOfColumns: self) {
                numberOfColumns = columns
            } else {
                numberOfColumns = 1;
            }
            
            if let s = delegate.streamView?(streamView, layoutSpacing: self) {
                spacing = s
            } else {
                spacing = 0
            }
            
            let num = CGFloat(numberOfColumns)
            if horizontal {
                size = (streamView.frame.size.height - spacing * (num + 1)) / num
            } else {
                size = (streamView.frame.size.width - spacing * (num + 1)) / num
            }
        }
    }
    
    override func horizontalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        var y = spacing
        var x = spacing
        if let previous = item.previous {
            let dy = CGRectGetMaxY(previous.frame)
            if dy + 2*spacing + size <= streamView.frame.size.height {
                y += dy
                x = previous.frame.origin.x
            } else {
                x = CGRectGetMaxX(previous.frame) + spacing
            }
        }
        return CGRect(origin: CGPointMake(x, y), size: CGSizeMake(size, size))
    }
    
    override func verticalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        var y = spacing
        var x = spacing
        if let previous = item.previous {
            let dx = CGRectGetMaxX(previous.frame)
            if dx + 2*spacing + size <= streamView.frame.size.width {
                x += dx
                y = previous.frame.origin.y
            } else {
                y = CGRectGetMaxY(previous.frame) + spacing
            }
        }
        return CGRect(origin: CGPointMake(x, y), size: CGSizeMake(size, size))
    }
}