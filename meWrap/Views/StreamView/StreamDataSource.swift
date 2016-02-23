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

class StreamDataSource: NSObject, GridLayoutDelegate, StreamLayoutDelegate {
    
    @IBOutlet weak var streamView: StreamView?
    
    lazy var headerMetrics = [StreamMetrics]()
    
    lazy var sectionHeaderMetrics = [StreamMetrics]()
    
    lazy var metrics = [StreamMetrics]()
    
    lazy var sectionFooterMetrics = [StreamMetrics]()
    
    lazy var footerMetrics = [StreamMetrics]()
    
    deinit {
        if (streamView?.delegate as? StreamDataSource) == self {
            streamView?.delegate = nil
        }
    }
    
    var items: BaseOrderedContainer? {
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
    
    lazy var autogeneratedMetrics: StreamMetrics = self.addMetrics(StreamMetrics())
    
    func addHeaderMetrics(metrics: StreamMetrics) -> StreamMetrics {
        headerMetrics.append(metrics)
        return metrics
    }
    
    func addSectionHeaderMetrics(metrics: StreamMetrics) -> StreamMetrics {
        sectionHeaderMetrics.append(metrics)
        return metrics
    }
    
    func addMetrics(metrics: StreamMetrics) -> StreamMetrics {
        self.metrics.append(metrics)
        return metrics
    }
    
    func addSectionFooterMetrics(metrics: StreamMetrics) -> StreamMetrics {
        sectionFooterMetrics.append(metrics)
        return metrics
    }
    
    func addFooterMetrics(metrics: StreamMetrics) -> StreamMetrics {
        footerMetrics.append(metrics)
        return metrics
    }
    
    var placeholderMetrics: StreamMetrics?
    
    @IBOutlet var scrollDirectionLayoutPrioritizer: LayoutPrioritizer?
    
    convenience init(streamView: StreamView) {
        self.init()
        self.streamView = streamView
        streamView.delegate = self
    }
    
    func refresh(sender: Refresher) {
        refresh({ (_) -> Void in
            sender.setRefreshing(false, animated: true)
            }) { (error) -> Void in
                sender.setRefreshing(false, animated: true)
        }
    }
    
    func refresh() {
        refresh(nil, failure: nil)
    }
    
    func refresh(success: ObjectBlock?, failure: FailureBlock?) {
        success?(nil)
    }
    
    func setRefreshable() {
        setRefreshableWithStyle(.White)
    }
    
    func setRefreshableWithStyle(style: RefresherStyle) {
        if let streamView = streamView {
            let refresher = Refresher(scrollView: streamView)
            refresher.style = style
            refresher.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        }
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
        return items?.tryAt(item.position.index)
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
    
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetrics] {
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
    
    func streamViewHeaderMetrics(streamView: StreamView) -> [StreamMetrics] {
        return headerMetrics
    }
    
    func streamViewFooterMetrics(streamView: StreamView) -> [StreamMetrics] {
        return footerMetrics
    }
    
    func streamView(streamView: StreamView, headerMetricsInSection section: Int) -> [StreamMetrics] {
        return sectionHeaderMetrics
    }
    
    func streamView(streamView: StreamView, footerMetricsInSection section: Int) -> [StreamMetrics] {
        return sectionFooterMetrics
    }
    
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetrics? {
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

extension StreamDataSource {
    @IBInspectable var itemIdentifier: String? {
        set { autogeneratedMetrics.identifier = newValue }
        get { return autogeneratedMetrics.identifier }
    }
    @IBOutlet var itemNibOwner: AnyObject? {
        set { autogeneratedMetrics.nibOwner = newValue }
        get { return autogeneratedMetrics.nibOwner }
    }
    @IBInspectable var itemSize: CGFloat {
        set { autogeneratedMetrics.size = newValue }
        get { return autogeneratedMetrics.size }
    }
    @IBInspectable var itemInsets: CGRect {
        set { autogeneratedMetrics.insets = newValue }
        get { return autogeneratedMetrics.insets }
    }
}