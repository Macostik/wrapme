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
    var isEdgeSeporator = false
    
    override func prepareLayout() {
        if let sv = self.streamView, let delegate = sv.delegate as? GridLayoutDelegate {
            numberOfColumns = delegate.streamView(sv, layoutNumberOfColumns: self)
            
            spacing = delegate.streamView(sv, layoutSpacing: self)
            
            let num = CGFloat(numberOfColumns)
            if horizontal {
                size = (sv.frame.height - spacing * (num + 1)) / num
            } else {
                size = (sv.frame.width - spacing * (num + (isEdgeSeporator ? 1 : -1))) / num
            }
            
            offset = delegate.streamView(sv, layout: self, offsetForColumn: 0)
        }
    }
    
    override func horizontalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        var x = spacing
        var y = spacing
        var column: Int = 0
        if let previous = item.previous {
            if previous.column < numberOfColumns - 1 {
                column = previous.column + 1
                x = previous.frame.origin.x
                y = size * CGFloat(column) + spacing * (CGFloat(column) + 1)
                item.column = column
            } else {
                x = previous.frame.maxX + spacing
            }
        }
        return CGRect(x: x, y: y, width: size, height: size)
    }
    
    override func verticalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let metrics = item.metrics
        if metrics.isSeparator {
            var y = offset + spacing
            if let previous = item.previous {
                y = previous.frame.maxY + spacing
            }
            return CGRect(x: 0, y: y, width: streamView.width, height: metrics.sizeAt(item))
        } else {
            var x = CGFloat(isEdgeSeporator) * spacing
            var y = offset + spacing
            var column: Int = 0
            if let previous = item.previous {
                if metrics.isSeparator || previous.metrics.isSeparator {
                    y = previous.frame.maxY + spacing
                } else {
                    if previous.column < numberOfColumns - 1 {
                        column = previous.column + 1
                        y = previous.frame.origin.y
                        x = size * CGFloat(column) + spacing * (CGFloat(column) + (CGFloat(isEdgeSeporator) * 1))
                        item.column = column
                    } else {
                        y = previous.frame.maxY + spacing
                    }
                }
            }
            return CGRect(x: x, y: y, width: size, height: size)
        }
    }
}

class SquareLayout: StreamLayout {
    
    var size: CGFloat = 0
    var spacing: CGFloat = 0
    
    override func prepareLayout() {
        if let streamView = self.streamView, let delegate = streamView.delegate as? GridLayoutDelegate {
            spacing =  delegate.streamView(streamView, layoutSpacing: self)
            if horizontal {
                size = streamView.frame.size.height - spacing*2
            } else {
                size = streamView.frame.size.width - spacing*2
            }
        }
    }
    
    override func horizontalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        var x = spacing
        if let previous = item.previous {
            x += CGRectGetMaxX(previous.frame)
        }
        return CGRect(origin: CGPointMake(x, spacing), size: CGSizeMake(size, size))
    }
    
    override func verticalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        var y = spacing
        if let previous = item.previous {
            y += CGRectGetMaxY(previous.frame)
        }
        return CGRect(origin: CGPointMake(spacing, y), size: CGSizeMake(size, size))
    }
}