//
//  PaginatedStreamDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class PaginatedStreamDataSource: StreamDataSource {
    
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
    
    var paginatedSet: PaginatedList?
    
    override var items: BaseOrderedContainer? {
        get {
            return paginatedSet
        }
        set {
            if let set = newValue as? PaginatedList {
                paginatedSet = set
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
    
    override func refresh(success: ObjectBlock?, failure: FailureBlock?) {
        paginatedSet?.newer(success, failure: failure)
    }
    
    func append(success: ObjectBlock?, failure: FailureBlock?) {
        paginatedSet?.older(success, failure: failure)
    }
    
    func isAppendable() -> Bool {
        if let appendableBlock = appendableBlock where !appendableBlock(self) {
            return false
        } else {
            return !(paginatedSet?.completed ?? true)
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
}

extension PaginatedStreamDataSource: PaginatedListNotifying {
    func listChanged(list: List) {
        reload()
    }
    func paginatedListDidStartLoading(set: PaginatedList) {
        setLoading(set.count == 0 && !set.completed)
    }
    func paginatedListDidFinishLoading(set: PaginatedList) {
        setLoading(false)
    }
}

extension PaginatedStreamDataSource: NetworkNotifying {
    func networkDidChangeReachability(network: Network) {
        if network.reachable {
            network.removeReceiver(self)
            if let streamView = streamView {
                appendItemsIfNeededWithTargetContentOffset(streamView.contentOffset)
            }
        }
    }
}