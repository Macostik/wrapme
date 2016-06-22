//
//  StreamDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class StreamDataSource<T: BaseOrderedContainer>: NSObject, StreamViewDataSource, UIScrollViewDelegate {
    
    @IBOutlet weak var streamView: StreamView?
    
    lazy var sectionHeaderMetrics = [StreamMetricsProtocol]()
    
    lazy var metrics = [StreamMetricsProtocol]()
    
    lazy var sectionFooterMetrics = [StreamMetricsProtocol]()
    
    deinit {
        if (streamView?.delegate as? StreamDataSource) == self {
            streamView?.delegate = nil
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
        if let streamView = streamView, let delegate = streamView.delegate as? StreamDataSource where delegate == self {
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
    
    private var contentSizeCategoryObserver: NotificationObserver?
    
    convenience init(streamView: StreamView) {
        self.init()
        self.streamView = streamView
        streamView.delegate = self
        streamView.dataSource = self
        contentSizeCategoryObserver = NotificationObserver.contentSizeCategoryObserver({ [weak self] (_) in
            self?.reload()
        })
    }
    
    var numberOfItems: Int?
    
    var didLayoutItemBlock: (StreamItem -> Void)?
    
    private func entryForItem(item: StreamItem) -> AnyObject? {
        return items?[safe: item.position.index] as? AnyObject
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
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        VideoPlayer.pauseAll.notify()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didEndDecelerating?()
            VideoPlayer.resumeAll.notify()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        didEndDecelerating?()
        VideoPlayer.resumeAll.notify()
    }
}