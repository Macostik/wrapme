//
//  StreamDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class StreamDataSource<T: BaseOrderedContainer where T.ElementType: AnyObject>: NSObject, StreamViewDataSource, UIScrollViewDelegate {
    
    var streamView: StreamView
    
    var sectionHeaderMetrics = [StreamMetricsProtocol]()
    
    var metrics = [StreamMetricsProtocol]()
    
    var sectionFooterMetrics = [StreamMetricsProtocol]()
    
    deinit {
        if (streamView.delegate as? StreamDataSource) == self {
            streamView.delegate = nil
        }
    }
    
    var items: T? {
        didSet {
            didSetItems()
        }
    }
    
    func didSetItems() {
        reload()
    }
    
    func reload() {
        if streamView.dataSource as? StreamDataSource == self {
            streamView.reload()
        }
    }
    
    func addSectionHeaderMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        sectionHeaderMetrics.append(metrics)
        return metrics
    }
    
    func addMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        self.metrics.append(metrics)
        return metrics
    }
    
    func addSectionFooterMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        sectionFooterMetrics.append(metrics)
        return metrics
    }
    
    required init(streamView: StreamView) {
        self.streamView = streamView
        super.init()
        self.streamView = streamView
        streamView.delegate = self
        streamView.dataSource = self
        FontPresetter.presetter.subscribe(self) { [unowned self] (value) in
            self.reload()
        }
    }
    
    var numberOfItems: Int?
    
    var didLayoutItemBlock: (StreamItem -> Void)?
    
    private func entryForItem(item: StreamItem) -> AnyObject? {
        return items?[safe: item.position.index]
    }
    
    func numberOfItemsIn(section: Int) -> Int {
        return numberOfItems ?? items?.count ?? 0
    }
    
    func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol] {
        return metrics
    }
    
    func didLayoutItem(item: StreamItem) {
        didLayoutItemBlock?(item)
    }
    
    func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [weak self] item -> AnyObject? in
            return self?.entryForItem(item)
        }
    }
    
    func didChangeContentSize(oldContentSize: CGSize) {}
    
    func didLayout() {}
    
    func headerMetricsIn(section: Int) -> [StreamMetricsProtocol] {
        return sectionHeaderMetrics
    }
    
    func footerMetricsIn(section: Int) -> [StreamMetricsProtocol] {
        return sectionFooterMetrics
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    var didEndDecelerating: (() -> ())?
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didEndDecelerating?()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        didEndDecelerating?()
    }
}