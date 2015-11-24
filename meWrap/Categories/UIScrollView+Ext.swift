//
//  UIScrollView+Additions.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIScrollView {
    func setMinimumContentOffsetAnimated(animated: Bool) {
        setContentOffset(minimumContentOffset, animated: animated)
    }
    func setMaximumContentOffsetAnimated(animated: Bool) {
        setContentOffset(maximumContentOffset, animated: animated)
    }
    
    var minimumContentOffset: CGPoint {
        let insets = contentInset
        return CGPointMake(-insets.left, -insets.top)
    }
    
    var maximumContentOffset: CGPoint {
        let insets = contentInset
        let width = contentSize.width - (bounds.width - insets.right)
        let height = contentSize.height - (bounds.height - insets.bottom)
        let x = (width > -insets.left) ? width : -insets.left
        let y = (height > -insets.top) ? height : -insets.top
        return CGPoint(x: round(x), y: round(y))
    }
    
    func isPossibleContentOffset(offset: CGPoint) -> Bool {
        let min = minimumContentOffset
        let max = maximumContentOffset
        return offset.x >= min.x && offset.x <= max.x && offset.y >= min.y && offset.y <= max.y
    }
    
    func trySetContentOffset(offset: CGPoint) {
        if isPossibleContentOffset(offset) {
            contentOffset = offset
        }
    }
    
    func trySetContentOffset(offset: CGPoint, animated: Bool) {
        if isPossibleContentOffset(offset) {
            setContentOffset(offset, animated: animated)
        }
    }
    
    var scrollable: Bool {
        return (contentSize.width > fittingContentWidth) || (contentSize.height > fittingContentHeight)
    }
    
    var verticalContentInsets: CGFloat {
        return contentInset.top + contentInset.bottom
    }
    
    var horizontalContentInsets: CGFloat {
        return contentInset.left + contentInset.right
    }
    
    var fittingContentSize: CGSize {
        return CGSizeMake(fittingContentWidth, fittingContentHeight)
    }
    
    var fittingContentWidth: CGFloat {
        return frame.width - horizontalContentInsets
    }
    
    var fittingContentHeight: CGFloat {
        return frame.height - verticalContentInsets
    }
    
    func visibleRectOfRect(rect: CGRect) -> CGRect {
        return visibleRectOfRect(rect, offset:contentOffset)
    }
    
    func visibleRectOfRect(rect: CGRect, offset: CGPoint) -> CGRect {
        return CGRect(origin: offset, size: bounds.size).intersect(rect)
    }
}
