//
//  StreamView.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

enum ScrollDirection {
    case Unknown, Up, Down
}

var StreamViewCommonLocksChanged: String = "StreamViewCommonLocksChanged"

protocol StreamViewDataSource {
    func numberOfSections() -> Int
    func numberOfItemsIn(section: Int) -> Int
    func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol]
    func didLayoutItem(item: StreamItem)
    func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)?
    func didChangeContentSize(oldContentSize: CGSize)
    func didLayout()
    func headerMetricsIn(section: Int) -> [StreamMetricsProtocol]
    func footerMetricsIn(section: Int) -> [StreamMetricsProtocol]
}

extension StreamViewDataSource {
    func numberOfSections() -> Int { return 1 }
    func didLayoutItem(item: StreamItem) { }
    func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)? { return nil }
    func didChangeContentSize(oldContentSize: CGSize) { }
    func didLayout() { }
    func headerMetricsIn(section: Int) -> [StreamMetricsProtocol] { return [] }
    func footerMetricsIn(section: Int) -> [StreamMetricsProtocol] { return [] }
}

final class StreamView: UIScrollView {
    
    lazy var layout: StreamLayout = StreamLayout()
    
    private var reloadAfterUnlock = false
    
    var locks: Int = 0
    
    static var locks: Int = 0
    
    private var items = [StreamItem]()
    
    var dataSource: StreamViewDataSource?
    
    private weak var placeholderView: PlaceholderView?
    
    var placeholderViewBlock: (() -> PlaceholderView)?
    
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
    
    var didScrollUp: (() -> ())?
    var didScrollDown: (() -> ())?
    
    var trackScrollDirection = false
    
    var direction: ScrollDirection = .Unknown {
        didSet {
            if direction != oldValue {
                if direction == .Up {
                    didScrollUp?()
                } else {
                    didScrollDown?()
                }
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if trackScrollDirection && tracking && (contentSize.height > height || direction == .Up) {
            direction = panGestureRecognizer.translationInView(self).y > 0 ? .Down : .Up
        }
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
        placeholderView?.removeFromSuperview()
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
        
        layout.prepareLayout(self)
        
        addItems()
        
        if let item = items.last {
            changeContentSize(layout.contentSize(item, streamView: self))
        } else {
            if layout.horizontal {
                changeContentSize(CGSizeMake(0, height))
            } else {
                changeContentSize(CGSizeMake(width, 0))
            }
        }
        
        layout.finalizeLayout()
        
        _layoutSize = layoutSize(layer.bounds)
        
        dataSource?.didLayout()
        
        updateVisibility()
    }
    
    private func changeContentSize(newContentSize: CGSize) {
        let oldContentSize = contentSize
        if !CGSizeEqualToSize(newContentSize, oldContentSize) {
            contentSize = newContentSize
            dataSource?.didChangeContentSize(oldContentSize)
        }
    }
    
    private func addItems() {
        
        guard let dataSource = dataSource else { return }
        let layout = self.layout
        
        for section in 0..<dataSource.numberOfSections() {
            
            let position = StreamPosition(section: section, index: 0)
            for header in dataSource.headerMetricsIn(section) {
                addItem(metrics: header, position: position)
            }
            
            for i in 0..<dataSource.numberOfItemsIn(section) {
                let position = StreamPosition(section: section, index: i);
                for metrics in dataSource.metricsAt(position) {
                    if let item = addItem(dataSource, metrics: metrics, position: position) {
                        dataSource.didLayoutItem(item)
                    }
                }
            }
            
            for footer in dataSource.footerMetricsIn(section) {
                addItem(metrics: footer, position: position)
            }
            
            layout.prepareForNextSection()
        }
        
        if items.isEmpty, let placeholder = placeholderViewBlock {
            let placeholderView = placeholder()
            add(placeholderView, { (make) in
                make.centerX.equalTo(self)
                make.centerY.equalTo(self).offset(layout.offset/2)
                make.size.lessThanOrEqualTo(self).offset(-24)
            })
            self.placeholderView = placeholderView
        }
    }
    
    private func addItem(dataSource: StreamViewDataSource? = nil, metrics: StreamMetricsProtocol, position: StreamPosition) -> StreamItem? {
        let item = StreamItem(metrics: metrics, position: position)
        item.entryBlock = dataSource?.entryBlockForItem(item)
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
            let offset = (item.frame.origin.x - contentInset.right) - fittingContentWidth / 2 + item.frame.size.width / 2
            if offset < minOffset.x {
                setContentOffset(minOffset, animated: animated)
            } else if offset > maxOffset.x {
                setContentOffset(maxOffset, animated: animated)
            } else {
                setContentOffset(CGPointMake(offset, 0), animated: animated)
            }
        } else {
            let offset = (item.frame.origin.y - contentInset.top) - fittingContentHeight / 2 + item.frame.size.height / 2
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