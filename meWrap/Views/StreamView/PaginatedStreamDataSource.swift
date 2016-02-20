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
        metrics.sizeAt = { [weak self] _ -> CGFloat in
            guard let sv = self?.streamView else { return 0 }
            return sv.horizontal ? sv.fittingContentWidth : sv.fittingContentHeight
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
    
    func setLoading(var loading: Bool) {
        if !Network.sharedNetwork.reachable {
            loading = false
        }
        
        if (placeholderMetrics?.hidden != loading || loadingMetrics.hidden == loading) {
            placeholderMetrics?.hidden = loading
            loadingMetrics.hidden = !loading
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
        if streamView.horizontal {
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