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
    
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetrics]
    
    optional func streamView(streamView: StreamView, didLayoutItem item: StreamItem)
    
    optional func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)?
    
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
            return layout?.horizontal ?? false
        }
        set {
            layout?.horizontal = newValue
        }
    }
    
    var numberOfSections: Int = 1
    
    var reloadAfterUnlock = false
    
    var locks: Int = 0
    
    static var locks: Int = 0
    
    var currentLayoutItem: StreamItem?
    
    var rootItem: StreamItem?
    
    var latestVisibleItem: StreamItem?
    
    deinit {
        delegate = nil
        unsubscribeFromOffsetChange()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:StreamViewCommonLocksChanged, object:nil)
    }
    
    func setup() {
        subscribeOnOffsetChange()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locksChanged", name: StreamViewCommonLocksChanged, object: nil)
    }
    
    private func unsubscribeFromOffsetChange() {
        layer.removeObserver(self, forKeyPath:"bounds")
    }
    
    private func subscribeOnOffsetChange() {
        layer.addObserver(self, forKeyPath: "bounds", options: .New, context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let layout = layout where layout.finalized {
            updateVisibility()
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
        var item = rootItem
        while let next = item {
            if let view = next.view {
                view.hidden = true
                next.metrics.enqueueView(view)
            }
            item = next.next
        }
        rootItem = nil
        currentLayoutItem = nil
        latestVisibleItem = nil
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
        
        guard let layout = self.layout, let delegate = self.delegate as? StreamViewDelegate else {
            return
        }
        
        numberOfSections = delegate.streamViewNumberOfSections?(self) ?? 1
        
        layout.prepareLayout()
        
        addItems(delegate, layout: layout);
        
        if let item = rootItem {
            layout.layoutItem(item)
        }
        
        layout.finalizeLayout()
        
        delegate.streamViewDidLayout?(self)
        
        updateVisibility()
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
                        item.entryBlock = delegate.streamView?(self, entryBlockForItem: item)
                        delegate.streamView?(self, didLayoutItem: item)
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
        
        if rootItem == nil, let placeholder = delegate.streamViewPlaceholderMetrics?(self) {
            if horizontal {
                placeholder.size = self.fittingContentWidth - layout.offset
            } else {
                placeholder.size = self.fittingContentHeight - layout.offset
            }
            addItem(layout, metrics:placeholder, position:StreamPosition(section: 0, index: 0))
        }
    }
    
    func addItem(layout: StreamLayout, metrics: StreamMetrics, position: StreamPosition) -> StreamItem? {
        if (!metrics.hiddenAt(position, metrics)) {
            let item = StreamItem(metrics: metrics, position: position)
            if let currentItem = currentLayoutItem {
                item.previous = currentItem
                currentItem.next = item
            }
            currentLayoutItem = item
            
            if rootItem == nil {
                rootItem = item
            }
            return item
        }
        return nil
    }
    
    func updateVisibility() {
        updateVisibility(withRect: layer.bounds)
    }
    
    func updateVisibility(withRect rect: CGRect) {
        guard let startItem = latestVisibleItem ?? rootItem else {
            return
        }
        var item: StreamItem? = startItem
        while let next = item {
            updateItemVisibility(next, visible: next.frame.intersects(rect))
            item = next.next
        }
        
        item = startItem.previous
        while let previous = item {
            updateItemVisibility(previous, visible: previous.frame.intersects(rect))
            item = previous.previous
        }
    }
    
    func updateItemVisibility(item: StreamItem, visible: Bool) {
        guard item.visible != visible else {
            return
        }
        item.visible = visible
        if (visible) {
            if let view = item.metrics.dequeueViewWithItem(item) {
                if view.superview != self {
                    insertSubview(view, atIndex: 0)
                }
                view.hidden = false
            }
            latestVisibleItem = item
        } else {
            if let view = item.view {
                item.metrics.enqueueView(view)
                view.hidden = true
                item.view = nil
            }
        }
    }
    
    func dynamicSizeForMetrics(metrics: StreamMetrics, entry: AnyObject?) -> CGFloat {
        guard let view = metrics.loadView() else { return 0 }
        view.width = width
        view.entry = entry
        let size = view.contentView!.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return size.height
    }
    
    // MARK: - User Actions
    
    func visibleItems() -> Set<StreamItem> {
        return itemsPassingTest { $0.visible }
    }
    
    func selectedItems() -> Set<StreamItem> {
        return itemsPassingTest { $0.selected }
    }
    
    var selectedItem: StreamItem? {
        return itemPassingTest { $0.selected }
    }
    
    func itemPassingTest(test: (StreamItem) -> Bool) -> StreamItem? {
        var item = rootItem
        while let next = item {
            if test(next) {
                return next
            }
            item = next.next
        }
        return nil
    }
    
    func itemsPassingTest(test: (StreamItem) -> Bool) -> Set<StreamItem> {
        var items: Set<StreamItem> = Set()
        var item = rootItem
        while let next = item {
            if test(next) {
                items.insert(next)
            }
            item = next.next
        }
        return items
    }
    
    func scrollToItem(item: StreamItem?, animated: Bool)  {
        if let _item = item {
            let minOffset = minimumContentOffset
            let maxOffset = maximumContentOffset
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