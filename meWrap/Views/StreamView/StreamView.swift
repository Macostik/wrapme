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

protocol StreamViewDelegate: UIScrollViewDelegate {
    func streamView(streamView: StreamView, numberOfItemsInSection section: Int) -> Int
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetrics]
    func streamView(streamView: StreamView, didLayoutItem item: StreamItem)
    func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)?
    func streamViewWillChangeContentSize(streamView: StreamView, newContentSize: CGSize)
    func streamViewDidChangeContentSize(streamView: StreamView, oldContentSize: CGSize)
    func streamViewDidLayout(streamView: StreamView)
    func streamViewHeaderMetrics(streamView: StreamView) -> [StreamMetrics]
    func streamViewFooterMetrics(streamView: StreamView) -> [StreamMetrics]
    func streamView(streamView: StreamView, headerMetricsInSection section: Int) -> [StreamMetrics]
    func streamView(streamView: StreamView, footerMetricsInSection section: Int) -> [StreamMetrics]
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetrics?
    func streamViewNumberOfSections(streamView: StreamView) -> Int
}

extension StreamViewDelegate {
    func streamView(streamView: StreamView, didLayoutItem item: StreamItem) { }
    func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)? { return nil }
    func streamViewWillChangeContentSize(streamView: StreamView, newContentSize: CGSize) { }
    func streamViewDidChangeContentSize(streamView: StreamView, oldContentSize: CGSize) { }
    func streamViewDidLayout(streamView: StreamView) { }
    func streamViewHeaderMetrics(streamView: StreamView) -> [StreamMetrics] { return [] }
    func streamViewFooterMetrics(streamView: StreamView) -> [StreamMetrics] { return [] }
    func streamView(streamView: StreamView, headerMetricsInSection section: Int) -> [StreamMetrics] { return [] }
    func streamView(streamView: StreamView, footerMetricsInSection section: Int) -> [StreamMetrics] { return [] }
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetrics? { return nil }
    func streamViewNumberOfSections(streamView: StreamView) -> Int { return 1 }
}

final class StreamView: UIScrollView {
    
    lazy var layout: StreamLayout = StreamLayout(streamView: self)
    
    @IBInspectable var horizontal: Bool {
        get { return layout.horizontal }
        set { layout.horizontal = newValue }
    }
    
    var numberOfSections: Int = 1
    
    private var reloadAfterUnlock = false
    
    var locks: Int = 0
    
    static var locks: Int = 0
    
    private weak var currentLayoutItem: StreamItem?
    
    private weak var rootItem: StreamItem?
    
    private weak var latestVisibleItem: StreamItem?
    
    private var items = [StreamItem]()
    
    deinit {
        delegate = nil
        unsubscribeFromOffsetChange()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:StreamViewCommonLocksChanged, object:nil)
    }
    
    private func setup() {
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
        if layout.finalized {
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
    
    private func clear() {
        var item = rootItem
        while let next = item {
            if let view = next.view {
                view.hidden = true
                next.metrics.enqueueView(view)
            }
            item = next.next
        }
        items.removeAll()
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
        
        guard let delegate = self.delegate as? StreamViewDelegate else { return }
        
        numberOfSections = delegate.streamViewNumberOfSections(self)
        
        layout.prepareLayout()
        
        addItems(delegate, layout: layout);
        
        if let item = rootItem {
            layout.layoutItem(item)
        }
        
        layout.finalizeLayout()
        
        delegate.streamViewDidLayout(self)
        
        updateVisibility()
    }
    
    func changeContentSize(newContentSize: CGSize) {
        if let delegate = self.delegate as? StreamViewDelegate {
            let oldContentSize = contentSize
            if !CGSizeEqualToSize(newContentSize, oldContentSize) {
                delegate.streamViewWillChangeContentSize(self, newContentSize: newContentSize)
                contentSize = newContentSize
                delegate.streamViewDidChangeContentSize(self, oldContentSize: oldContentSize)
            }
        }
    }
    
    private func addItems(delegate: StreamViewDelegate, layout: StreamLayout) {
        
        for header in delegate.streamViewHeaderMetrics(self) {
            addItem(metrics: header, position: StreamPosition.zero)
        }
        
        for section in 0..<numberOfSections {
            
            let position = StreamPosition(section: section, index: 0)
            for header in delegate.streamView(self, headerMetricsInSection: section) {
                addItem(metrics: header, position: position)
            }
            
            for i in 0..<delegate.streamView(self, numberOfItemsInSection:section) {
                let position = StreamPosition(section: section, index: i);
                for metrics in delegate.streamView(self, metricsAt:position) {
                    if let item = addItem(delegate, metrics: metrics, position: position) {
                        delegate.streamView(self, didLayoutItem: item)
                    }
                }
            }
            
            for footer in delegate.streamView(self, footerMetricsInSection: section) {
                addItem(metrics: footer, position: position)
            }
            
            layout.prepareForNextSection()
        }
        
        for footer in delegate.streamViewFooterMetrics(self) {
            addItem(metrics: footer, position: StreamPosition.zero)
        }
        
        if rootItem == nil, let placeholder = delegate.streamViewPlaceholderMetrics(self) {
            if horizontal {
                placeholder.size = self.fittingContentWidth - layout.offset
            } else {
                placeholder.size = self.fittingContentHeight - layout.offset
            }
            addItem(metrics: placeholder, position:StreamPosition.zero)
        }
    }
    
    private func addItem(delegate: StreamViewDelegate? = nil, metrics: StreamMetrics, position: StreamPosition) -> StreamItem? {
        let item = StreamItem(metrics: metrics, position: position)
        item.entryBlock = delegate?.streamView(self, entryBlockForItem: item)
        metrics.modifyItem?(item)
        guard !item.hidden else { return nil }
        if let currentItem = currentLayoutItem {
            item.previous = currentItem
            currentItem.next = item
        }
        currentLayoutItem = item
        
        if rootItem == nil {
            rootItem = item
        }
        items.append(item)
        return item
    }
    
    private func updateVisibility() {
        updateVisibility(withRect: layer.bounds)
    }
    
    private func updateVisibility(withRect rect: CGRect) {
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
    
    private func updateItemVisibility(item: StreamItem, visible: Bool) {
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
    
    func dynamicSizeForMetrics(metrics: StreamMetrics, item: StreamItem?, minSize: CGFloat) -> CGFloat {
        guard let view = metrics.loadView() else { return minSize }
        view.entry = item?.entry
        var fittingSize = UILayoutFittingCompressedSize
        fittingSize.width = width
        let size = view.contentView!.systemLayoutSizeFittingSize(fittingSize, withHorizontalFittingPriority: 1000, verticalFittingPriority: 250)
        return max(minSize, size.height)
    }
    
    // MARK: - User Actions
    
    func visibleItems() -> [StreamItem] {
        return itemsPassingTest { $0.visible }
    }
    
    func selectedItems() -> [StreamItem] {
        return itemsPassingTest { $0.selected }
    }
    
    var selectedItem: StreamItem? {
        return itemPassingTest { $0.selected }
    }
    
    func itemPassingTest(@noescape test: (StreamItem) -> Bool) -> StreamItem? {
        var item = rootItem
        while let next = item {
            if test(next) {
                return next
            }
            item = next.next
        }
        return nil
    }
    
    func itemsPassingTest(@noescape test: (StreamItem) -> Bool) -> [StreamItem] {
        var items = [StreamItem]()
        var item = rootItem
        while let next = item {
            if test(next) {
                items.append(next)
            }
            item = next.next
        }
        return items
    }
    
    func scrollToItemPassingTest(@noescape test: (StreamItem) -> Bool, animated: Bool) -> StreamItem? {
        let item = itemPassingTest(test)
        scrollToItem(item, animated: animated)
        return item
    }
    
    func scrollToItem(item: StreamItem?, animated: Bool)  {
        guard let item = item else { return }
        let minOffset = minimumContentOffset
        let maxOffset = maximumContentOffset
        if horizontal {
            let offset = item.frame.origin.x - fittingContentWidth / 2 + item.frame.size.width / 2
            if offset < minOffset.x {
                setContentOffset(minOffset, animated: animated)
            } else if offset > maxOffset.x {
                setContentOffset(maxOffset, animated: animated)
            } else {
                setContentOffset(CGPointMake(offset, 0), animated: animated)
            }
        } else {
            let offset = item.frame.origin.y - fittingContentHeight / 2 + item.frame.size.height / 2
            if offset < minOffset.y {
                setContentOffset(minOffset, animated: animated)
            } else if offset > maxOffset.y {
                setContentOffset(maxOffset, animated: animated)
            } else {
                setContentOffset(CGPointMake(0, offset), animated: animated)
            }
        }
    }
    
    override func touchesShouldCancelInContentView(view: UIView) -> Bool {
        if view is UIButton {
            return true
        }
        return super.touchesShouldCancelInContentView(view)
    }
}