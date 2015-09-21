//
//  StreamView.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

var StreamViewCommonLocksChanged: String = "StreamViewCommonLocksChanged"

@objc protocol StreamViewDelegate: UIScrollViewDelegate {
    func streamView(streamView: StreamView, numberOfItemsInSection section: Int) -> Int
    
    func streamView(streamView: StreamView, didLayoutItem item: StreamItem)
    
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetrics]
    
    optional func streamViewWillChangeContentSize(streamView: StreamView, newContentSize: CGSize)
    
    optional func streamViewDidChangeContentSize(streamView: StreamView, oldContentSize: CGSize)
    
    optional func streamViewDidLayout(streamView: StreamView)
    
    optional func streamViewHeaderMetrics(streamView: StreamView) -> [StreamMetrics]
    
    optional func streamViewFooterMetrics(streamView: StreamView) -> [StreamMetrics]
    
    optional func streamView(streamView: StreamView, headerMetricsInSection section: Int) -> [StreamMetrics]
    
    optional func streamView(streamView: StreamView, footerMetricsInSection section: Int) -> [StreamMetrics]
    
    optional func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetrics?
    
    optional func streamViewNumberOfSections(streamView: StreamView) -> Int
}

class StreamView: UIScrollView {
    
    var _layout: StreamLayout?
    
    @IBOutlet var layout: StreamLayout? {
        get {
            if _layout == nil {
                self.layout = StreamLayout()
            }
            return _layout
        }
        set {
            if let layout = newValue {
                layout.streamView = self
                _layout = layout
            }
        }
    }
    
    @IBInspectable var horizontal: Bool {
        get {
            if let layout = self.layout {
                return layout.horizontal
            } else {
                return false
            }
        }
        set {
            layout?.horizontal = newValue
        }
    }
    
    var numberOfSections = 1
    
    lazy var items: Set<StreamItem> = Set()
    
    var reloadAfterUnlock = false
    
    var locks: Int = 0
    
    static var locks: Int = 0
    
    weak var currentLayoutItem: StreamItem?
    
    weak var firstItem: StreamItem?
    
    deinit {
        removeObserver(self, forKeyPath:"contentOffset")
        NSNotificationCenter.defaultCenter().removeObserver(self, name:StreamViewCommonLocksChanged, object:nil)
    }
    
    func setup() {
        addObserver(self, forKeyPath: "contentOffset", options: .New, context: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locksChanged", name: StreamViewCommonLocksChanged, object: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let layout = layout where layout.finalized {
            updateVisibility()
        }
    }
    
    override var contentOffset: CGPoint {
        didSet {
            if let layout = layout where layout.finalized {
                updateVisibility()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func clear() {
        firstItem = nil
        currentLayoutItem = nil
        for item in items {
            if let view = item.view {
                view.removeFromSuperview()
                item.metrics?.enqueueView(view)
            }
        }
        items.removeAll(keepCapacity: false)
    }
    
    class func lock() {
        locks++
    }
    
    class func unlock() {
        if (locks > 0) {
            locks--
            NSNotificationCenter.defaultCenter().postNotificationName(StreamViewCommonLocksChanged, object: nil)
        }
    }
    
    func locksChanged() {
        if (locks == 0 && StreamView.locks == 0 && reloadAfterUnlock) {
            reloadAfterUnlock = false
            reload()
        }
    }
    
    func lock() {
        locks++
    }
    
    func unlock() {
        if (locks > 0) {
            locks--
            locksChanged()
        }
    }
    
    func reload() {
        
        if locks > 0 || StreamView.locks > 0 {
            reloadAfterUnlock = true
            return
        }
        
        clear()
        
        if let layout = self.layout, let delegate = self.delegate as? StreamViewDelegate {
            
            if let numberOfSections = delegate.streamViewNumberOfSections?(self) {
                self.numberOfSections = numberOfSections
            } else {
                numberOfSections = 1
            }
            
            layout.prepareLayout()
            
            addItems(delegate, layout: layout);
            
            if let item = firstItem {
                layout.layoutItem(item)
            }
            
            layout.finalizeLayout()
            
            delegate.streamViewDidLayout?(self)
            
            updateVisibility()
        }
    }
    
    func changeContentSize(newContentSize: CGSize) {
        if let delegate = self.delegate as? StreamViewDelegate {
            let oldContentSize = contentSize
            if !CGSizeEqualToSize(newContentSize, oldContentSize) {
                delegate.streamViewWillChangeContentSize?(self, newContentSize: newContentSize)
                contentSize = newContentSize
                delegate.streamViewDidChangeContentSize?(self, oldContentSize: oldContentSize)
            }
        }
    }
    
    func addItems(delegate: StreamViewDelegate, layout: StreamLayout) {
        
        if let headers = delegate.streamViewHeaderMetrics?(self) {
            for header in headers {
                addItem(layout, metrics: header, position: StreamPosition(section: 0, index: 0))
            }
        }
        
        for section in 0..<numberOfSections {
            
            let sectionIndex = StreamPosition(section: section, index: 0)
            
            if let headers = delegate.streamView?(self, headerMetricsInSection: section) {
                for header in headers {
                    addItem(layout, metrics: header, position: sectionIndex)
                }
            }
            
            let numberOfItems = delegate.streamView(self, numberOfItemsInSection:section)
            
            for i in 0..<numberOfItems {
                let index = StreamPosition(section: section, index: i);
                let metrics = delegate.streamView(self, metricsAt:index)
                for itemMetrics in metrics {
                    if let item = addItem(layout, metrics: itemMetrics, position: index) {
                        delegate.streamView(self, didLayoutItem: item)
                    }
                }
            }
            
            if let footers = delegate.streamView?(self, footerMetricsInSection: section) {
                for footer in footers {
                    addItem(layout, metrics: footer, position: sectionIndex)
                }
            }
            
            
            layout.prepareForNextSection()
        }
        
        if let footers = delegate.streamViewFooterMetrics?(self) {
            for footer in footers {
                addItem(layout, metrics: footer, position: StreamPosition(section: 0, index: 0))
            }
        }
        
        if items.count == 0 {
            if let placeholder = delegate.streamViewPlaceholderMetrics?(self) {
                if horizontal {
                    placeholder.size = self.fittingContentWidth
                } else {
                    placeholder.size = self.fittingContentHeight
                }
                addItem(layout, metrics:placeholder, position:StreamPosition(section: 0, index: 0))
            }
        }
    }
    
    func addItem(layout: StreamLayout, metrics: StreamMetrics, position: StreamPosition) -> StreamItem? {
        if (!metrics.hiddenAt(position, metrics)) {
            let item = StreamItem()
            item.position = position
            item.metrics = metrics
            if let currentItem = currentLayoutItem {
                item.previous = currentItem
                currentItem.next = item
            }
            currentLayoutItem = item
            items.insert(item)
            
            if firstItem == nil {
                firstItem = item
            }
            return item
        }
        return nil
    }
    
    func updateVisibility() {
        updateVisibility(withRect: CGRect(origin: contentOffset, size: frame.size))
    }
    
    func updateVisibility(withRect rect: CGRect) {
        if let item = (firstItem != nil) ? firstItem : items.first {
            recursivelyUpdateItemVisibility(item, rect: rect) { (item) -> StreamItem? in
                if let previous = item.previous where !item.visible && previous.visible {
                    return nil
                } else {
                    return item.next
                }
            }
            if let item = item.previous {
                recursivelyUpdateItemVisibility(item, rect: rect) { (item) -> StreamItem? in
                    if let next = item.next where !item.visible && next.visible {
                        return nil
                    } else {
                        return item.previous
                    }
                }
            }
        }
    }
    
    func recursivelyUpdateItemVisibility(item: StreamItem, rect: CGRect, next:((StreamItem) -> StreamItem?)) {
        let visible = CGRectIntersectsRect(item.frame, rect)
        if item.visible != visible {
            item.visible = visible
            if let metrics = item.metrics {
                if (visible) {
                    if let view = metrics.dequeueViewWithItem(item) {
                        insertSubview(view, atIndex: 0)
                    }
                    firstItem = item
                } else {
                    if let view = item.view {
                        metrics.enqueueView(view)
                        view.removeFromSuperview()
                        item.view = nil
                    }
                }
            }
        }
        
        if let nextItem = next(item) {
            recursivelyUpdateItemVisibility(nextItem, rect: rect, next: next)
        }
    }
    
    // MARK: - User Actions
    
    func visibleItems() -> Set<StreamItem> {
        return itemsPassingTest({ (item) -> Bool in
            return item.visible
        })
    }
    
    func selectedItems() -> Set<StreamItem> {
        return itemsPassingTest({ (item) -> Bool in
            return item.selected
        })
    }
    
    var selectedItem: StreamItem? {
        return itemPassingTest({ (item) -> Bool in
            return item.selected
        })
    }
    
    func itemPassingTest(test: (StreamItem) -> Bool) -> StreamItem? {
        for item in items {
            if test(item) {
                return item
            }
        }
        return nil
    }
    
    func itemsPassingTest(test: (StreamItem) -> Bool) -> Set<StreamItem> {
        var _items: Set<StreamItem> = Set()
        for item in items {
            if test(item) {
                _items.insert(item)
            }
        }
        return _items
    }
    
    func scrollToItem(item: StreamItem?, animated: Bool)  {
        let minOffset = minimumContentOffset
        let maxOffset = maximumContentOffset
        
        if let _item = item {
            
            if horizontal {
                let offset = _item.frame.origin.x - self.fittingContentWidth / 2 + _item.frame.size.width / 2
                if offset < minOffset.x {
                    self.setContentOffset(minOffset, animated: animated)
                } else if offset > maxOffset.x {
                    self.setContentOffset(maxOffset, animated: animated)
                } else {
                    self.setContentOffset(CGPointMake(offset, 0), animated: animated)
                }
            } else {
                let offset = _item.frame.origin.y - self.fittingContentHeight / 2 + _item.frame.size.height / 2
                if offset < minOffset.y {
                    self.setContentOffset(minOffset, animated: animated)
                } else if offset > maxOffset.y {
                    self.setContentOffset(maxOffset, animated: animated)
                } else {
                    self.setContentOffset(CGPointMake(0, offset), animated: animated)
                }
            }
        }
    }
    
}