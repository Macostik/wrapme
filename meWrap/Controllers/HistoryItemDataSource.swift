//
//  HistoryItemDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class HistoryItemDataSource: PaginatedStreamDataSource {
    
    func fixedContentOffset(scrollView: UIScrollView, offset: CGFloat) -> CGFloat {
        let size = scrollView.width/2.5 + layoutSpacing
        return min(scrollView.maximumContentOffset.x, max(0.0, size))
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if let item = items as? WLHistoryItem {
            item.offset = scrollView.contentOffset
        }
        super.scrollViewDidScroll(scrollView)
    }
    
    override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let offset = targetContentOffset.memory.x
        let maxOffset = scrollView.maximumContentOffset.x
        if offset > 0 && abs(offset - maxOffset) > 1 {
            targetContentOffset.memory.x = fixedContentOffset(scrollView, offset: offset)
        }
        super.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}