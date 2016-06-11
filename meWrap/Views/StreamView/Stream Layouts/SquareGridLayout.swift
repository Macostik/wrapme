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
    
    internal var currentOffset: CGFloat = 0
    
    override func prepareLayout(sv: StreamView) {
        let num = CGFloat(numberOfColumns)
        size = (sv.frame.width - spacing * (num + (isEdgeSeporator ? 1 : -1))) / num
        currentOffset = offset
    }
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let metrics = item.metrics
        if metrics.isSeparator {
            var y = currentOffset + spacing
            if let previous = item.previous {
                y = previous.frame.maxY + spacing
            }
            return CGRect(x: 0, y: y, width: streamView.width, height: item.size)
        } else {
            var x = CGFloat(isEdgeSeporator) * spacing
            var y = currentOffset + spacing
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

class HorizontalSquareGridLayout: SquareGridLayout {
    
    override var horizontal: Bool { return true }
    
    override func prepareLayout(sv: StreamView) {
        let num = CGFloat(numberOfColumns)
        size = (sv.frame.height - spacing * (num + (isEdgeSeporator ? 1 : -1))) / num
        currentOffset = offset
    }
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
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
}

class SquareLayout: StreamLayout {
    
    var size: CGFloat = 0
    var spacing: CGFloat = 0
    
    override func prepareLayout(streamView: StreamView) {
        size = streamView.frame.size.width - spacing*2
    }
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        var y = spacing
        if let previous = item.previous {
            y += CGRectGetMaxY(previous.frame)
        }
        return CGRect(origin: CGPointMake(spacing, y), size: CGSizeMake(size, size))
    }
}

class HorizontalSquareLayout: SquareLayout {
    
    override var horizontal: Bool { return true }
    
    override func prepareLayout(streamView: StreamView) {
        size = streamView.frame.size.height - spacing*2
    }
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        var x = spacing
        if let previous = item.previous {
            x += CGRectGetMaxX(previous.frame)
        }
        return CGRect(origin: CGPointMake(x, spacing), size: CGSizeMake(size, size))
    }
}