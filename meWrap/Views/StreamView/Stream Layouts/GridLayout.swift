//
//  GridLayout.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

@objc protocol GridLayoutDelegate: StreamViewDelegate {

    optional func streamView(streamView: StreamView, layoutNumberOfColumns layout: StreamLayout) -> Int

    optional func streamView(streamView: StreamView, layout: StreamLayout, offsetForColumn column: Int)  -> CGFloat

    optional func streamView(streamView: StreamView, layout: StreamLayout, sizeForColumn column: Int) -> CGFloat

    optional func streamView(streamView: StreamView, layoutSpacing layout: StreamLayout)  -> CGFloat

}

class GridLayout: StreamLayout {
    
    var numberOfColumns: Int = 1
    var offsets: Array<CGFloat> = [0]
    var sizes: Array<CGFloat> = [1]
    var spacing: CGFloat = 0
    
    func position(column: Int) -> CGFloat {
        var position: CGFloat = 0
        for i in 0..<column {
            position += sizes[i]
        }
        return position * (horizontal ? streamView!.frame.size.height : streamView!.frame.size.width)
    }
    
    func minimumOffset() -> (offset: CGFloat, column: Int) {
        var offset: CGFloat = CGFloat.max
        var column: Int = 0
        for i in 0..<offsets.count {
            let r = offsets[i];
            if (r < offset) {
                column = i;
                offset = r;
            }
        }
        return (offset, column);
    }
    
    func maximumOffset() -> (offset: CGFloat, column: Int) {
        var offset: CGFloat = 0
        var column: Int = 0
        for i in 0..<offsets.count {
            let r = offsets[i];
            if (r > offset) {
                column = i;
                offset = r;
            }
        }
        return (offset, column);
    }
    
    override func prepareLayout() {
        if let delegate = streamView?.delegate as? GridLayoutDelegate {
            if let columns = delegate.streamView?(streamView!, layoutNumberOfColumns: self) {
                numberOfColumns = columns
            } else {
                numberOfColumns = 1;
            }
            sizes = Array(count: numberOfColumns, repeatedValue: 0)
            offsets = Array(count: numberOfColumns, repeatedValue: 0)
            
            for column in 0..<numberOfColumns {
                if let size = delegate.streamView?(streamView!, layout: self, sizeForColumn: column) {
                    sizes[column] = size;
                } else {
                    sizes[column] = (streamView!.frame.size.width / CGFloat(numberOfColumns)) / streamView!.frame.size.width;
                }
                
                if let offset = delegate.streamView?(streamView!, layout: self, offsetForColumn: column) {
                    offsets[column] = offset
                }
            }
            
            if let s = delegate.streamView?(streamView!, layoutSpacing: self) {
                spacing = s
            } else {
                spacing = 0
            }
        }
    }

    override func layout(item: StreamItem) -> StreamItem {
    
        var ratio: CGFloat = 1
        
        if let metrics = item.metrics {
            if let metrics = item.metrics as? GridMetrics {
                ratio = metrics.ratioAt(item.position!, metrics)
            } else {
                ratio = (horizontal ? streamView!.frame.size.height : streamView!.frame.size.width) / metrics.sizeAt(item.position!, metrics)
            }
        }
        
        let result = minimumOffset()
        let offset = result.offset
        let column = result.column
        let size = sizes[column] * (horizontal ? streamView!.frame.size.height : streamView!.frame.size.width)
        
        let spacing_2 = spacing/2.0
        var frame = CGRectZero
        if horizontal {
            frame.origin.x = offset
            frame.size.width = size / ratio - spacing
            if (column == 0) {
                frame.origin.y = position(column) + spacing
                frame.size.height = size - (spacing + spacing_2)
            } else if (column == numberOfColumns - 1) {
                frame.origin.y = position(column) + spacing_2;
                frame.size.height = size - (spacing + spacing_2)
            } else {
                frame.origin.y = position(column) + spacing_2;
                frame.size.height = size - spacing;
            }
            offsets[column] = CGRectGetMaxX(frame) + spacing;
        } else {
            frame.origin.y = offset
            frame.size.height = size / ratio - spacing
            if (column == 0) {
                frame.origin.x = position(column) + spacing;
                frame.size.width = size - (spacing + spacing_2)
                
            } else if (column == numberOfColumns - 1) {
                frame.origin.x = position(column) + spacing_2
                frame.size.width = size - (spacing + spacing_2)
            } else {
                frame.origin.x = position(column) + spacing_2
                frame.size.width = size - spacing
            }
            offsets[column] = CGRectGetMaxY(frame) + spacing;
        }
        
        item.frame = frame
        return item;
    }
    
    func flatten() {
        let offset = maximumOffset().offset
        for i in 0..<offsets.count {
            offsets[i] = offset
        }
    }
    
    override func prepareForNextSection() {
        flatten()
    }
    
    override var contentSize: CGSize {
        if horizontal {
            return CGSizeMake(maximumOffset().offset, streamView!.frame.size.height);
        } else {
            return CGSizeMake(streamView!.frame.size.width, maximumOffset().offset);
        }
    }
}