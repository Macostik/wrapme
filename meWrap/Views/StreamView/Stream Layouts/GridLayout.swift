//
//  GridLayout.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

protocol GridLayoutDelegate: StreamViewDelegate {
    func streamView(streamView: StreamView, layoutNumberOfColumns layout: StreamLayout) -> Int
    func streamView(streamView: StreamView, layout: StreamLayout, offsetForColumn column: Int)  -> CGFloat
    func streamView(streamView: StreamView, layout: StreamLayout, sizeForColumn column: Int) -> CGFloat
    func streamView(streamView: StreamView, layoutSpacing layout: StreamLayout)  -> CGFloat
}

extension GridLayoutDelegate {
    func streamView(streamView: StreamView, layoutNumberOfColumns layout: StreamLayout) -> Int { return 1 }
    func streamView(streamView: StreamView, layout: StreamLayout, offsetForColumn column: Int)  -> CGFloat { return 0 }
    func streamView(streamView: StreamView, layout: StreamLayout, sizeForColumn column: Int) -> CGFloat { return 1 }
    func streamView(streamView: StreamView, layoutSpacing layout: StreamLayout)  -> CGFloat { return 0 }
}

class GridLayout: StreamLayout {
    
    var numberOfColumns: Int = 1
    var spacing: CGFloat = 0
    
    private var offsets = [CGFloat]()
    private var sizes = [CGFloat]()
    
    func position(column: Int) -> CGFloat {
        guard let sv = streamView else {
            return 0
        }
        var position: CGFloat = 0
        for i in 0..<column {
            position += sizes[i]
        }
        return position * (horizontal ? sv.frame.height : sv.frame.width)
    }
    
    override func prepareLayout() {
        if let sv = streamView, let delegate = sv.delegate as? GridLayoutDelegate {
            numberOfColumns = delegate.streamView(sv, layoutNumberOfColumns: self)
            let sizeBase = horizontal ? sv.frame.height : sv.frame.width
            let defaultSize = (sizeBase / CGFloat(numberOfColumns)) / sizeBase
            sizes = Array(count: numberOfColumns, repeatedValue: defaultSize)
            offsets = Array(count: numberOfColumns, repeatedValue: 0)
            
            for column in 0..<numberOfColumns {
                sizes[column] = delegate.streamView(sv, layout: self, sizeForColumn: column)
                offsets[column] = delegate.streamView(sv, layout: self, offsetForColumn: column)
            }
            
            spacing = delegate.streamView(sv, layoutSpacing: self)
        }
    }
    
    override func horizontalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        
        let ratio = item.ratio
        
        let offset = offsets.minElement() ?? 0
        let column = offsets.indexOf(offset) ?? 0
        let size = sizes[column] * streamView.frame.height
        
        let spacing_2 = spacing/2.0
        var frame = CGRectZero
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
        offsets[column] = frame.maxX + spacing;
        return frame
    }
    
    override func verticalFrameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let ratio = item.ratio
        let offset = offsets.minElement() ?? 0
        let column = offsets.indexOf(offset) ?? 0
        let size = sizes[column] * streamView.frame.width
        
        let spacing_2 = spacing/2.0
        var frame = CGRectZero
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
        offsets[column] = frame.maxY + spacing;
        return frame
    }
    
    func flatten() {
        let offset = offsets.maxElement() ?? 0
        for i in 0..<offsets.count {
            offsets[i] = offset
        }
    }
    
    override func prepareForNextSection() {
        flatten()
    }
}