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

    optional func streamView(streamView:StreamView, offsetForlayout:StreamLayout) -> CGFloat

}

class StreamLayout: NSObject {
    
    var streamView: StreamView?
    
    @IBInspectable var horizontal: Bool = false
    
    var contentSize: CGSize {
        if (horizontal) {
            return CGSizeMake(offset, streamView!.frame.size.height);
        } else {
            return CGSizeMake(streamView!.frame.size.width, offset);
        }
    }
    
    private var offset: CGFloat = 0
    
    func prepareLayout() {
        if let delegate = streamView?.delegate as? StreamLayoutDelegate {
            if let offset = delegate.streamView?(streamView!, offsetForlayout: self) {
                self.offset = offset
            } else {
                self.offset = 0
            }
        }
    }
    
    func layout(item: StreamItem) -> StreamItem {
        let size = item.metrics!.sizeAt(item.index!, item.metrics!)
        let insets = item.metrics!.insetsAt(item.index!, item.metrics!)
        if (self.horizontal) {
            item.frame = CGRectMake(offset + insets.origin.x, insets.origin.y, size + insets.size.width, streamView!.frame.size.height - 2*insets.size.height)
        } else {
            item.frame = CGRectMake(insets.origin.x, offset + insets.origin.y, streamView!.frame.size.width - 2*insets.size.width, size + insets.size.height)
        }
        offset += size;
        return item;
    }
    
    func prepareForNextSection() {
    
    }
    
    func finalizeLayout() {
        prepareForNextSection()
    }
}