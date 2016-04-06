//
//  PaginatedStreamDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class PaginatedStreamDataSource<T: PaginatedListProtocol>: StreamDataSource<T> {
    
    var appendableBlock: (PaginatedStreamDataSource -> Bool)?
    
    lazy var loadingMetrics: StreamMetrics = {
        let metrics = self.addFooterMetrics(LoadingView.metrics())
        metrics.modifyItem = { [weak self] item in
            if let sv = self?.streamView {
                item.size = sv.layout.horizontal ? sv.fittingContentWidth : sv.fittingContentHeight
            }
        }
        metrics.hidden = true
        return metrics
    }()
    
    override var items: T? {
        didSet {
            if let set = items {
                set.addReceiver(self)
                setLoading(set.count == 0 && !set.completed)
                didSetItems()
            }
        }
    }
    
    func setLoading(loading: Bool) {
        var _loading = loading
        if !Network.sharedNetwork.reachable {
          _loading = false
        }
        
        if (placeholderMetrics?.hidden != _loading || loadingMetrics.hidden == _loading) {
            placeholderMetrics?.hidden = _loading
            loadingMetrics.hidden = !_loading
            reload()
        }
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
    
    func setRefreshable() {
        setRefreshableWithStyle(.White)
    }
    
    func setRefreshableWithStyle(style: RefresherStyle) {
        if let streamView = streamView {
            let refresher = Refresher(scrollView: streamView)
            refresher.style = style
            refresher.addTarget(self, action: #selector(self.refresh(_:)), forControlEvents: .ValueChanged)
        }
    }
    
    func refresh(success: ([T.PaginatedEntryType] -> ())?, failure: FailureBlock?) {
        items?.newer(success, failure: failure)
    }
    
    func append(success: ([T.PaginatedEntryType] -> ())?, failure: FailureBlock?) {
        items?.older(success, failure: failure)
    }
    
    func isAppendable() -> Bool {
        if let appendableBlock = appendableBlock where !appendableBlock(self) {
            return false
        } else {
            return !(items?.completed ?? true)
        }
    }
    
    func appendItemsIfNeededWithTargetContentOffset(targetContentOffset: CGPoint) {
        guard let streamView = streamView else { return }
        
        var reachedRequiredOffset = false
        if streamView.layout.horizontal {
            reachedRequiredOffset = (streamView.maximumContentOffset.x - targetContentOffset.x) < streamView.fittingContentWidth
        } else {
            reachedRequiredOffset = (streamView.maximumContentOffset.y - targetContentOffset.y) < streamView.fittingContentHeight
        }
        
        if reachedRequiredOffset && isAppendable() {
            if Network.sharedNetwork.reachable {
                append(nil, failure: { $0?.showNonNetworkError() })
            } else {
                Network.sharedNetwork.addReceiver(self)
            }
        }
    }
    
    override func streamViewDidLayout(streamView: StreamView) {
        super.streamViewDidLayout(streamView)
        Dispatch.mainQueue.async { () -> Void in
            self.appendItemsIfNeededWithTargetContentOffset(streamView.contentOffset)
        }
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        appendItemsIfNeededWithTargetContentOffset(targetContentOffset.memory)
    }
    
    func networkDidChangeReachability(network: Network) {
        if network.reachable {
            network.removeReceiver(self)
            if let streamView = streamView {
                appendItemsIfNeededWithTargetContentOffset(streamView.contentOffset)
            }
        }
    }
}

extension PaginatedStreamDataSource: PaginatedListNotifying {
    func listChanged<T: Equatable>(list: List<T>) {
        reload()
    }
    func paginatedListDidStartLoading<T: Equatable>(set: PaginatedList<T>) {
        setLoading(set.count == 0 && !set.completed)
    }
    func paginatedListDidFinishLoading<T: Equatable>(set: PaginatedList<T>) {
        setLoading(false)
    }
}
