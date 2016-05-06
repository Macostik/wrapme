//
//  StreamDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

enum ScrollDirection {
    case Unknown, Up, Down
}

class StreamDataSource<T: BaseOrderedContainer>: NSObject, GridLayoutDelegate, StreamLayoutDelegate {
    
    @IBOutlet weak var streamView: StreamView?
    
    lazy var headerMetrics = [StreamMetricsProtocol]()
    
    lazy var sectionHeaderMetrics = [StreamMetricsProtocol]()
    
    lazy var metrics = [StreamMetricsProtocol]()
    
    lazy var sectionFooterMetrics = [StreamMetricsProtocol]()
    
    lazy var footerMetrics = [StreamMetricsProtocol]()
    
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
    
    func addHeaderMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        headerMetrics.append(metrics)
        return metrics
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
    
    func addFooterMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        footerMetrics.append(metrics)
        return metrics
    }
    
    var placeholderMetrics: StreamMetricsProtocol?
    
    @IBOutlet var scrollDirectionLayoutPrioritizer: LayoutPrioritizer?
    
    convenience init(streamView: StreamView) {
        self.init()
        self.streamView = streamView
        streamView.delegate = self
    }
    
    var numberOfItems: Int?
    
    @IBInspectable var layoutOffset: CGFloat = 0
    
    @IBInspectable var layoutSpacing: CGFloat = 0
    
    @IBInspectable var numberOfGridColumns: Int = 1
    
    @IBInspectable var sizeForGridColumns: CGFloat = 1
    
    @IBInspectable var offsetForGridColumns: CGFloat = 0
    
    var didLayoutItemBlock: (StreamItem -> Void)?
    
    var willChangeContentSizeBlock: (CGSize -> Void)?
    
    var didChangeContentSizeBlock: (CGSize -> Void)?
    
    var didLayoutBlock: (Void -> Void)?
    
    private func entryForItem(item: StreamItem) -> AnyObject? {
        return items?[safe: item.position.index] as? AnyObject
    }
    
    // MARK: - UIScrollViewDelegate
    
    private var direction: ScrollDirection = .Unknown {
        didSet {
            if direction != oldValue {
                scrollDirectionLayoutPrioritizer?.setDefaultState(direction == .Down, animated: true)
            }
        }
    }
    
    func streamView(streamView: StreamView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems ?? items?.count ?? 0
    }
    
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetricsProtocol] {
        return metrics
    }
    
    func streamView(streamView: StreamView, didLayoutItem item: StreamItem) {
        didLayoutItemBlock?(item)
    }
    
    func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [weak self] item -> AnyObject? in
            return self?.entryForItem(item)
        }
    }
    
    func streamViewWillChangeContentSize(streamView: StreamView, newContentSize: CGSize) {
        willChangeContentSizeBlock?(newContentSize)
    }
    
    func streamViewDidChangeContentSize(streamView: StreamView, oldContentSize: CGSize) {
        didChangeContentSizeBlock?(oldContentSize)
    }
    
    func streamViewDidLayout(streamView: StreamView) {
        didLayoutBlock?()
    }
    
    func streamViewHeaderMetrics(streamView: StreamView) -> [StreamMetricsProtocol] {
        return headerMetrics
    }
    
    func streamViewFooterMetrics(streamView: StreamView) -> [StreamMetricsProtocol] {
        return footerMetrics
    }
    
    func streamView(streamView: StreamView, headerMetricsInSection section: Int) -> [StreamMetricsProtocol] {
        return sectionHeaderMetrics
    }
    
    func streamView(streamView: StreamView, footerMetricsInSection section: Int) -> [StreamMetricsProtocol] {
        return sectionFooterMetrics
    }
    
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetricsProtocol? {
        return placeholderMetrics
    }
    
    func streamViewNumberOfSections(streamView: StreamView) -> Int {
        return 1
    }
}

extension StreamDataSource {
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.tracking && (scrollView.contentSize.height > scrollView.height || direction == .Up) {
            direction = scrollView.panGestureRecognizer.translationInView(scrollView).y > 0 ? .Down : .Up
        }
    }
}

extension StreamDataSource {
    // MARK: - GridLayoutDelegate
    
    func streamView(streamView: StreamView, layoutNumberOfColumns layout: StreamLayout) -> Int {
        return numberOfGridColumns
    }
    
    func streamView(streamView: StreamView, layout: StreamLayout, offsetForColumn column: Int)  -> CGFloat {
        return offsetForGridColumns
    }
    
    func streamView(streamView: StreamView, layout: StreamLayout, sizeForColumn column: Int) -> CGFloat {
        return sizeForGridColumns
    }
    
    func streamView(streamView: StreamView, layoutSpacing layout: StreamLayout)  -> CGFloat {
        return layoutSpacing
    }
}

extension StreamDataSource {
    // MARK: - StreamLayoutDelegate
    
    func streamView(streamView:StreamView, offsetForLayout:StreamLayout) -> CGFloat {
        return layoutOffset
    }
}