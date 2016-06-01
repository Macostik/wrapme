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
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetricsProtocol]
    func streamView(streamView: StreamView, didLayoutItem item: StreamItem)
    func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)?
    func streamViewWillChangeContentSize(streamView: StreamView, newContentSize: CGSize)
    func streamViewDidChangeContentSize(streamView: StreamView, oldContentSize: CGSize)
    func streamViewDidLayout(streamView: StreamView)
    func streamViewHeaderMetrics(streamView: StreamView) -> [StreamMetricsProtocol]
    func streamViewFooterMetrics(streamView: StreamView) -> [StreamMetricsProtocol]
    func streamView(streamView: StreamView, headerMetricsInSection section: Int) -> [StreamMetricsProtocol]
    func streamView(streamView: StreamView, footerMetricsInSection section: Int) -> [StreamMetricsProtocol]
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetricsProtocol?
    func streamViewNumberOfSections(streamView: StreamView) -> Int
}

extension StreamViewDelegate {
    func streamView(streamView: StreamView, didLayoutItem item: StreamItem) { }
    func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)? { return nil }
    func streamViewWillChangeContentSize(streamView: StreamView, newContentSize: CGSize) { }
    func streamViewDidChangeContentSize(streamView: StreamView, oldContentSize: CGSize) { }
    func streamViewDidLayout(streamView: StreamView) { }
    func streamViewHeaderMetrics(streamView: StreamView) -> [StreamMetricsProtocol] { return [] }
    func streamViewFooterMetrics(streamView: StreamView) -> [StreamMetricsProtocol] { return [] }
    func streamView(streamView: StreamView, headerMetricsInSection section: Int) -> [StreamMetricsProtocol] { return [] }
    func streamView(streamView: StreamView, footerMetricsInSection section: Int) -> [StreamMetricsProtocol] { return [] }
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetricsProtocol? { return nil }
    func streamViewNumberOfSections(streamView: StreamView) -> Int { return 1 }
}

final class StreamView: UIScrollView {
    
    lazy var layout: StreamLayout = StreamLayout()
    
    var numberOfSections: Int = 1
    
    private var reloadAfterUnlock = false
    
    var locks: Int = 0
    
    static var locks: Int = 0
    
    private var items = [StreamItem]()
    
   override var contentInset: UIEdgeInsets  {
        didSet {
            if oldValue != contentInset && items.count == 1 && layout.finalized {
                reload()
            }
        }
    }

    deinit {
        delegate = nil
        unsubscribeFromOffsetChange()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:StreamViewCommonLocksChanged, object:nil)
    }
    
    private func setup() {
        subscribeOnOffsetChange()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamView.locksChanged), name: StreamViewCommonLocksChanged, object: nil)
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
        for item in items {
            if let view = item.view {
                view.hidden = true
                item.metrics.enqueueView(view)
            }
        }
        items.removeAll()
    }
    
    class func lock() {
        locks += 1
    }
    
    class func unlock() {
        if (locks > 0) {
            locks -= 1
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
        locks += 1
    }
    
    func unlock() {
        if (locks > 0) {
            locks -= 1
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
        
        layout.prepareLayout(self)
        
        addItems(delegate, layout: layout);
        
        if let item = items.last {
            changeContentSize(layout.contentSize(item, streamView: self))
        } else {
            if layout.horizontal {
                contentSize = CGSizeMake(layout.offset, height)
            } else {
                contentSize = CGSizeMake(width, layout.offset)
            }
        }
                
        layout.finalizeLayout()
        
        _layoutSize = layoutSize(layer.bounds)
        
        delegate.streamViewDidLayout(self)
        
        updateVisibility()
    }
    
    private func changeContentSize(newContentSize: CGSize) {
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
        
        if items.isEmpty, let placeholder = delegate.streamViewPlaceholderMetrics(self) {
            if layout.horizontal {
                placeholder.size = self.fittingContentWidth - layout.offset
            } else {
                placeholder.size = self.fittingContentHeight - layout.offset
            }
            addItem(metrics: placeholder, position:StreamPosition.zero)
        }
    }
    
    private func addItem(delegate: StreamViewDelegate? = nil, metrics: StreamMetricsProtocol, position: StreamPosition) -> StreamItem? {
        let item = StreamItem(metrics: metrics, position: position)
        item.entryBlock = delegate?.streamView(self, entryBlockForItem: item)
        metrics.modifyItem?(item)
        guard !item.hidden else { return nil }
        if let currentItem = items.last {
            item.previous = currentItem
            currentItem.next = item
        }
        layout.layoutItem(item, streamView: self)
        items.append(item)
        return item
    }
    
    private func updateVisibility() {
        updateVisibility(withRect: layer.bounds)
    }
    
    private var _layoutSize: CGFloat = 0
    
    private func layoutSize(rect: CGRect) -> CGFloat {
        return layout.horizontal ? rect.height : rect.width
    }
    
    private func reloadIfNeeded(rect: CGRect) -> Bool {
        let size = layoutSize(rect)
        if abs(_layoutSize - size) >= 1 {
            reload()
            return true
        } else {
            return false
        }
    }
    
    private func updateVisibility(withRect rect: CGRect) {
        guard !reloadIfNeeded(rect) else { return }
        for item in items {
            let visible = item.frame.intersects(rect)
            if item.visible != visible {
                item.visible = visible
                if visible {
                    let view = item.metrics.dequeueViewWithItem(item)
                    if view.superview != self {
                        insertSubview(view, atIndex: 0)
                    }
                    view.hidden = false
                } else if let view = item.view {
                    item.metrics.enqueueView(view)
                    view.hidden = true
                    item.view = nil
                }
            }
        }
    }
    
    func dynamicSizeForMetrics(metrics: StreamMetricsProtocol, item: StreamItem?, minSize: CGFloat) -> CGFloat {
        let view = metrics.loadView()
        view.setEntry(item?.entry)
        var fittingSize = UILayoutFittingCompressedSize
        fittingSize.width = width
        let size = view.systemLayoutSizeFittingSize(fittingSize, withHorizontalFittingPriority: 1000, verticalFittingPriority: 250)
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
        for item in items where test(item) {
            return item
        }
        return nil
    }
    
    func itemsPassingTest(@noescape test: (StreamItem) -> Bool) -> [StreamItem] {
        return items.filter(test)
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
        if layout.horizontal {
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
        return true
    }
}