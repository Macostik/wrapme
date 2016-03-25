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
        var position: CGFloat = 0
        for i in 0..<column {
            position += sizes[i]
        }
        return position
    }
    
    override func prepareLayout(sv: StreamView) {
        if let delegate = sv.delegate as? GridLayoutDelegate {
            numberOfColumns = delegate.streamView(sv, layoutNumberOfColumns: self)
            let sizeBase = sv.frame.width
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
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let ratio = item.ratio
        let offset = offsets.minElement() ?? 0
        let column = offsets.indexOf(offset) ?? 0
        let x = position(column) * streamView.frame.width
        let size = sizes[column] * streamView.frame.width
        
        let spacing_2 = spacing/2.0
        var frame = CGRectZero
        frame.origin.y = offset
        frame.size.height = size / ratio - spacing
        if (column == 0) {
            frame.origin.x = x + spacing;
            frame.size.width = size - (spacing + spacing_2)
            
        } else if (column == numberOfColumns - 1) {
            frame.origin.x = x + spacing_2
            frame.size.width = size - (spacing + spacing_2)
        } else {
            frame.origin.x = x + spacing_2
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

class HorizontalGridLayout: GridLayout {
    
    override var horizontal: Bool { return true }
    
    override func prepareLayout(sv: StreamView) {
        if let delegate = sv.delegate as? GridLayoutDelegate {
            numberOfColumns = delegate.streamView(sv, layoutNumberOfColumns: self)
            let sizeBase = sv.frame.height
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
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        
        let ratio = item.ratio
        
        let offset = offsets.minElement() ?? 0
        let column = offsets.indexOf(offset) ?? 0
        let y = position(column) * streamView.frame.height
        let size = sizes[column] * streamView.frame.height
        
        let spacing_2 = spacing/2.0
        var frame = CGRectZero
        frame.origin.x = offset
        frame.size.width = size / ratio - spacing
        if (column == 0) {
            frame.origin.y = y + spacing
            frame.size.height = size - (spacing + spacing_2)
        } else if (column == numberOfColumns - 1) {
            frame.origin.y = y + spacing_2;
            frame.size.height = size - (spacing + spacing_2)
        } else {
            frame.origin.y = y + spacing_2;
            frame.size.height = size - spacing
        }
        offsets[column] = frame.maxX + spacing
        return frame
    }
}