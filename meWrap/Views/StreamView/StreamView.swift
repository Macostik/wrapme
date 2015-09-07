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
    
    func streamView(streamView: StreamView, entryAt index: StreamIndex) -> AnyObject?
    
    func streamView(streamView: StreamView, metricsAt index: StreamIndex) -> [StreamMetrics]
    
    optional func streamViewHeaderMetrics(streamView: StreamView) -> [StreamMetrics]
    
    optional func streamViewFooterMetrics(streamView: StreamView) -> [StreamMetrics]
    
    optional func streamView(streamView: StreamView, sectionHeaderMetricsInSection section: Int) -> [StreamMetrics]
    
    optional func streamView(streamView: StreamView, sectionFooterMetricsInSection section: Int) -> [StreamMetrics]
    
    optional func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetrics
    
    optional func streamViewNumberOfSections(streamView: StreamView) -> Int
}

class StreamView: UIScrollView {
    
    @IBOutlet var layout: StreamLayout? {
        didSet {
            layout?.streamView = self
        }
    }
    
    var toggleSelection = false
    
    var multipleSelection = false
    
    @IBInspectable var horizontal: Bool {
        get {
            if (layout == nil) {
                return false
            } else {
                return layout!.horizontal
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
    
    deinit {
        removeObserver(self, forKeyPath:"contentOffset")
        NSNotificationCenter.defaultCenter().removeObserver(self, name:StreamViewCommonLocksChanged, object:nil)
    }
    
    func setup() {
        var tapRecognizer = UITapGestureRecognizer(target: self, action: "tap:")
        addGestureRecognizer(tapRecognizer)
        addObserver(self, forKeyPath: "contentOffset", options: .New, context: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locksChanged", name: StreamViewCommonLocksChanged, object: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if layout == nil {
            layout = StreamLayout()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        updateVisibility()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func clear() {
        for item in items {
            item.view?.removeFromSuperview()
        }
        items.removeAll(keepCapacity: false)
    }
    
    class func lock() {
        locks = max(0, locks + 1)
    }
    
    class func unlock() {
        if (locks > 0) {
            locks--
            NSNotificationCenter.defaultCenter().postNotificationName(StreamViewCommonLocksChanged, object: nil)
        }
    }
    
    func locksChanged() {
        if (locks == 0 && StreamView.locks == 0 && reloadAfterUnlock) {
            reloadAfterUnlock = false;
            reload()
        }
    }
    
    func lock() {
        locks = max(0, locks + 1);
    }
    
    func unlock() {
        if (locks > 0) {
            locks = locks - 1;
            locksChanged()
        }
    }
    
    func reload() {
        
        if (locks > 0 && StreamView.locks > 0) {
            reloadAfterUnlock = true
            return;
        }
        
        clear()
        
        if let layout = self.layout {
            layout.prepareLayout()
            
            if let delegate = self.delegate as? StreamViewDelegate {
                
                if let numberOfSections = delegate.streamViewNumberOfSections?(self) {
                    self.numberOfSections = numberOfSections
                } else {
                    numberOfSections = 1
                }
                
                if let headers = delegate.streamViewHeaderMetrics?(self) {
                    layoutMetrics(headers, layout: layout, index: StreamIndex(index: 0))
                }
                
                var count = items.count;
                
                for section in 0..<numberOfSections {
                    
                    var sectionIndex = StreamIndex(index:section)
                    
                    if let headers = delegate.streamView?(self, sectionHeaderMetricsInSection: section) {
                        layoutMetrics(headers, layout: layout, index: sectionIndex)
                    }
                    
                    var numberOfItems = delegate.streamView(self, numberOfItemsInSection:section)
                    
                    for i in 0..<numberOfItems {
                        var index = (sectionIndex.copy() as! StreamIndex).add(i)
                        let metrics = delegate.streamView(self, metricsAt:index)
                        layoutMetrics(metrics, layout: layout, index: index)
                    }
                    
                    if let footers = delegate.streamView?(self, sectionFooterMetricsInSection: section) {
                        layoutMetrics(footers, layout: layout, index: sectionIndex)
                    }
                    
                    
                    layout.prepareForNextSection()
                }
                
                var empty = items.count == count
                
                if let footers = delegate.streamViewFooterMetrics?(self) {
                    layoutMetrics(footers, layout: layout, index: StreamIndex(index: 0))
                }
                
                
                if (empty) {
                    if let placeholder = delegate.streamViewPlaceholderMetrics?(self) {
                        var size = frame.size;
                        var insets = contentInset;
                        if horizontal {
                            placeholder.size = size.width - insets.left - insets.right - layout.contentSize.width;
                        } else {
                            placeholder.size = size.height - insets.top - insets.bottom - layout.contentSize.height;
                        }
                        layoutItem(layout, metrics:placeholder, index:StreamIndex(index: 0))
                    }
                }
                
                layout.finalizeLayout()
                
                contentSize = layout.contentSize;
                
                updateVisibility()
            }
        }
    }
    
    func layoutMetrics(metrics: [StreamMetrics], layout: StreamLayout, index: StreamIndex) {
        for m in metrics {
            layoutItem(layout, metrics: m, index: index)
        }
    }
    
    func layoutItem(layout: StreamLayout, metrics: StreamMetrics, index: StreamIndex) {
        if (!metrics.hiddenAt(index, metrics)) {
            var item = StreamItem()
            item.index = index;
            item.metrics = metrics;
            layout.layout(item)
            if !CGSizeEqualToSize(item.frame.size, CGSizeZero) {
                items.insert(item)
            }
        }
    }
    
    func viewForItem(item: StreamItem) -> StreamReusableView? {
        if let view = item.metrics?.loadView() {
            view.frame = item.frame;
            item.view = view;
            var entry: AnyObject?
            if let delegate = self.delegate as? StreamViewDelegate {
                entry = delegate.streamView(self, entryAt: item.index!)
            }
            if let prepareAppearing = item.metrics?.prepareAppearing {
                prepareAppearing(item, entry)
            }
            view.entry = entry
            if let finalizeAppearing = item.metrics?.finalizeAppearing {
                finalizeAppearing(item, entry)
            }
            view.frame = item.frame
            return view
        }
        return nil
    }
    
    func updateVisibility() {
        var rect = CGRectMake(contentOffset.x, contentOffset.y, bounds.size.width, bounds.size.height)
        for item in items {
            
            var visible = CGRectIntersectsRect(item.frame, rect)
            if item.visible != visible {
                item.visible = visible
                if (visible) {
                    if let view = viewForItem(item) {
                        view.layer.geometryFlipped = self.layer.geometryFlipped
                        insertSubview(view, atIndex: 0)
                    }
                } else {
                    if let view = item.view {
                        view.removeFromSuperview()
                        item.metrics?.reusableViews.insert(view)
                    }
                }
            }
        }
    }
    
    // MARK: - User Actions
    
    func tap(recognizer: UITapGestureRecognizer) {
        touchedAt(recognizer.locationInView(self))
    }
    
    func touchedAt(point: CGPoint) {
        if let item = visibleItemAtPoint(point) {
            
            if toggleSelection {
                item.selected = !item.selected
            } else {
                item.selected = true
            }
            
            if item.selected {
                if multipleSelection {
                    for _item in items {
                        if _item != item {
                            _item.selected = false
                        }
                    }
                }
                
                if let delegate = self.delegate as? StreamViewDelegate {
                    if let entry: AnyObject = delegate.streamView(self, entryAt: item.index!) {
                        item.metrics?.select(item, entry: entry)
                    }
                }
            }
        }
    }
    
    func visibleItemAtPoint(point: CGPoint) -> StreamItem? {
        return itemPassingTest({ (item) -> Bool in
            return CGRectContainsPoint(item.frame, point)
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
    
    func scrollToItem(item: StreamItem, animated: Bool)  {
        scrollRectToVisible(item.frame, animated:animated)
    }
    
}