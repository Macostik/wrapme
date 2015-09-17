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
    var offsets: Array<CGFloat> = [0]
    var size: CGFloat = 0
    var spacing: CGFloat = 0
    
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
        if let streamView = self.streamView, let delegate = streamView.delegate as? GridLayoutDelegate {
            if let columns = delegate.streamView?(streamView, layoutNumberOfColumns: self) {
                numberOfColumns = columns
            } else {
                numberOfColumns = 1;
            }
            
            offsets = Array(count: numberOfColumns, repeatedValue: 0)
            
            for column in 0..<numberOfColumns {
                if let offset = delegate.streamView?(streamView, layout: self, offsetForColumn: column) {
                    offsets[column] = offset
                }
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
    
    override func layout(item: StreamItem) -> StreamItem {
        
        let result = minimumOffset()
        let offset = result.offset
        let column = CGFloat(result.column)
        let position = size * column + spacing * (column + 1)
        var frame = CGRectMake(0, 0, size, size)
        if horizontal {
            frame.origin = CGPointMake(offset, position)
            offsets[result.column] = CGRectGetMaxX(frame) + spacing;
        } else {
            frame.origin = CGPointMake(position, offset)
            offsets[result.column] = CGRectGetMaxY(frame) + spacing;
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