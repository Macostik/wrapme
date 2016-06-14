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
    
    var maxY: CGFloat {
        var maxY: CGFloat = 0
        for rect in completedFrames {
            if rect.maxY > maxY {
                maxY = rect.maxY
            }
        }
        return maxY
    }
    
    var completedFrames = [CGRect]()
}

class MosaicLayout: StreamLayout {
    
    var spacing: CGFloat = 0
    
    private var curentOffset: CGFloat = 0
    
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
            oldValue?.completedFrames = []
        }
    }
    
    override func contentSize(item: StreamItem, streamView: StreamView) -> CGSize {
        return CGSize(width: streamView.width, height: slice?.maxY ?? 0)
    }
    
    override func prepareLayout(sv: StreamView) {
        curentOffset = offset
        slice = slices[0]
        sliceIndex = 0
    }
    
    override func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        
        guard item.metrics.isSeparator == false else {
            return super.frameForItem(item, streamView: streamView)
        }
        
        guard var slice = slice else { return CGRect.zero }
        
        if slice.completedFrames.count == slice.items.count {
            curentOffset = slice.maxY
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
        
        let item = slice.items[slice.completedFrames.count]
        
        let size = streamView.frame.size.width
        
        var frame: CGRect = ((size * item[0]) ^ (curentOffset + size * item[1])) ^ ((size * item[2]) ^ (size * item[3]))
        
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
        
        slice.completedFrames.append(frame)
        
        return frame
    }
}