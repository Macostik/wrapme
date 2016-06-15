//
//  MosaicLayout.swift
//  meWrap
//
//  Created by Sergey Maximenko on 6/14/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

let v1_3: CGFloat = 1.0/3.0
let v2_1_3: CGFloat = 2*v1_3

final class MosaicSlice {
    
    static let separator = MosaicSlice(items: [[0, 0, v1_3, v1_3], [v1_3, 0, v1_3, v1_3], [2 * v1_3, 0, v1_3, v1_3]])
    
    let items: [[CGFloat]]
    init(items: [[CGFloat]]) {
        self.items = items
    }
    
    var numberOfCompletedFrames = 0
}

class MosaicLayout: StreamLayout {
    
    var spacing: CGFloat = 0
    
    private var currentOffset: CGFloat = 0
    private var sliceY: CGFloat = 0
    
    private var slices: [MosaicSlice] = [
        MosaicSlice.separator,
        MosaicSlice(items: [[0, 0, v2_1_3, v2_1_3], [v2_1_3, 0, v1_3, v1_3], [v2_1_3, v1_3, v1_3, v1_3]]),
        MosaicSlice.separator,
        MosaicSlice(items: [[0, 0, v1_3, v1_3], [v1_3, 0, v2_1_3, v2_1_3], [0, v1_3, v1_3, v1_3]]),
        MosaicSlice.separator,
        MosaicSlice(items: [[0, 0, v2_1_3, 1], [v2_1_3, 0, v1_3, v1_3], [v2_1_3, v1_3, v1_3, v1_3], [v2_1_3, v2_1_3, v1_3, v1_3]])
    ]
    
    private var sliceIndex = 0
    
    private var slice: MosaicSlice? {
        didSet {
            oldValue?.numberOfCompletedFrames = 0
        }
    }
    
    override func contentSize(item: StreamItem, streamView: StreamView) -> CGSize {
        return CGSize(width: streamView.width, height: currentOffset)
    }
    
    override func prepareLayout(sv: StreamView) {
        sliceY = offset
        currentOffset = offset
        for slice in slices {
            slice.numberOfCompletedFrames = 0
        }
        slice = slices[0]
        sliceIndex = 0
    }
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        
        guard item.metrics.isSeparator == false else {
            let frame = CGRectMake(0, currentOffset, streamView.frame.width, item.size)
            currentOffset = currentOffset + item.size
            sliceY = currentOffset
            return frame
        }
        
        guard var slice = slice else { return CGRect.zero }
        
        let size = streamView.frame.size.width
        
        if slice.numberOfCompletedFrames == slice.items.count {
            sliceY = currentOffset
            let index = sliceIndex + 1
            if index < slices.count {
                let _slice = slices[index]
                self.slice = _slice
                sliceIndex = index
                slice = _slice
            } else {
                let _slice = slices[0]
                self.slice = _slice
                sliceIndex = 0
                slice = _slice
            }
        }
        
        let item = slice.items[slice.numberOfCompletedFrames]
        
        var frame: CGRect = ((size * item[0]) ^ (sliceY + size * item[1])) ^ ((size * item[2]) ^ (size * item[3]))
        
        frame.origin.y = frame.origin.y + spacing
        frame.size.height = frame.size.height - spacing
        
        if frame.origin.x == 0 {
            frame.origin.x = spacing
            frame.size.width = frame.size.width - 1.5 * spacing
        } else if frame.maxX == size {
            frame.origin.x = frame.origin.x + 0.5 * spacing
            frame.size.width = frame.size.width - 1.5 * spacing
        } else {
            frame.origin.x = frame.origin.x + 0.5 * spacing
            frame.size.width = frame.size.width - spacing
        }
        
        slice.numberOfCompletedFrames = slice.numberOfCompletedFrames + 1
        
        if frame.maxY > currentOffset {
            currentOffset = frame.maxY
        }
        
        return frame
    }
    
    override func prepareForNextSection() {
        if let slice = slice where slice.numberOfCompletedFrames > 0 {
            slice.numberOfCompletedFrames = slice.items.count
            sliceY = currentOffset
        }
    }
}