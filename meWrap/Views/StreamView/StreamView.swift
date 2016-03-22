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
    
    private var items = [StreamItem]()
    
   override var contentInset: UIEdgeInsets  {
        didSet {
            if oldValue != contentInset && items.count == 1 && layout.finalized {
                reload()
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            if oldValue.size != frame.size && layout.finalized {
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
        
        layout.prepareLayout()
        
        addItems(delegate, layout: layout);
        
        if let item = items.first {
            layout.layoutItem(item)
        } else {
            contentSize = CGSize.zero
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
        
        if items.isEmpty, let placeholder = delegate.streamViewPlaceholderMetrics(self) {
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
        if let currentItem = items.last {
            item.previous = currentItem
            currentItem.next = item
        }
        items.append(item)
        return item
    }
    
    private func updateVisibility() {
        updateVisibility(withRect: layer.bounds)
    }
    
    private func updateVisibility(withRect rect: CGRect) {
        for item in items {
            let visible = item.frame.intersects(rect)
            if item.visible != visible {
                item.visible = visible
                if visible {
                    if let view = item.metrics.dequeueViewWithItem(item) {
                        if view.superview != self {
                            insertSubview(view, atIndex: 0)
                        }
                        view.hidden = false
                    }
                } else if let view = item.view {
                    item.metrics.enqueueView(view)
                    view.hidden = true
                    item.view = nil
                }
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