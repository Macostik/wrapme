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
    
    private var _loadingMetrics: StreamMetrics?
    var loadingMetrics: StreamMetrics? {
        if _loadingMetrics == nil {
            let metrics = addFooterMetrics(LoadingView.metrics())
            metrics.sizeAt = { [weak self] (position, metrics) -> CGFloat in
                guard let streamView = self?.streamView else {
                    return 0
                }
                return streamView.horizontal ? streamView.fittingContentWidth : streamView.fittingContentHeight
            }
            metrics.hidden = true
            _loadingMetrics = metrics
        }
        return _loadingMetrics
    }
    
    var paginatedSet: WLPaginatedSet?
    
    override var items: WLBaseOrderedCollection? {
        get {
            return paginatedSet
        }
        set {
            if let set = newValue as? WLPaginatedSet {
                paginatedSet = set
                set.delegate = self
                setLoading(set.count == 0 && !set.completed)
                didSetItems()
            }
        }
    }
    
    func setLoading(var loading: Bool) {
        if !WLNetwork.sharedNetwork().reachable {
            loading = false
        }
        
        guard let loadingMetrics = loadingMetrics else {
            return
        }
        
        if (autogeneratedPlaceholderMetrics.hidden != loading || loadingMetrics.hidden == loading) {
            autogeneratedPlaceholderMetrics.hidden = loading
            loadingMetrics.hidden = !loading
            reload()
        }
    }
    
    override func refresh(success: WLArrayBlock?, failure: WLFailureBlock?) {
        paginatedSet?.newer(success, failure: failure)
    }
    
    func append(success: WLArrayBlock?, failure: WLFailureBlock?) {
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
        guard let streamView = streamView else {
            return
        }
        
        var reachedRequiredOffset = false
        if streamView.horizontal {
            reachedRequiredOffset = (streamView.maximumContentOffset.x - targetContentOffset.x) < streamView.fittingContentWidth;
        } else {
            reachedRequiredOffset = (streamView.maximumContentOffset.y - targetContentOffset.y) < streamView.fittingContentHeight;
        }
        
        if reachedRequiredOffset && isAppendable() {
            if WLNetwork.sharedNetwork().reachable {
                append(nil, failure: { (error) -> Void in
                    error?.showNonNetworkError()
                })
            } else {
                WLNetwork.sharedNetwork().addReceiver(self)
            }
        }
    }
}

extension PaginatedStreamDataSource: WLPaginatedSetDelegate {
    func setDidChange(set: WLSet!) {
        reload()
    }
    func paginatedSetDidStartLoading(set: WLPaginatedSet) {
        setLoading(set.count == 0 && !set.completed)
    }
    func paginatedSetDidFinishLoading(set: WLPaginatedSet) {
        if set.loadingTypes.count == 0 {
            setLoading(false)
        } else {
            setLoading(set.count == 0 && !set.completed)
        }
    }
    override func streamViewDidLayout(streamView: StreamView) {
        super.streamViewDidLayout(streamView)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, 0)
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.appendItemsIfNeededWithTargetContentOffset(streamView.contentOffset)
        }
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        appendItemsIfNeededWithTargetContentOffset(targetContentOffset.memory)
    }
}

extension PaginatedStreamDataSource: WLNetworkReceiver {
    func networkDidChangeReachability(network: WLNetwork!) {
        if network.reachable {
            network.removeReceiver(self)
            if let streamView = streamView {
                appendItemsIfNeededWithTargetContentOffset(streamView.contentOffset)
            }
        }
    }
}