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
    
    weak var spinner: UIActivityIndicatorView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let spinner = spinner, let streamView = streamView {
                streamView.superview?.add(spinner, { (make) in
                    make.center.equalTo(streamView)
                })
            }
        }
    }
    
    override func didSetItems() {
        if let set = items {
            set.didChangeNotifier.subscribe(self, block: { [unowned self] (value) in
                self.reload()
                })
            set.didStartLoading.subscribe(self, block: { [unowned self] (value) in
                self.setLoading(set.count == 0 && !set.completed)
                })
            set.didFinishLoading.subscribe(self, block: { [unowned self] (value) in
                self.setLoading(false)
                })
            setLoading(set.count == 0 && !set.completed)
            
        }
        super.didSetItems()
    }
    
    func setLoading(loading: Bool) {
        guard let streamView = streamView else { return }
        let loading = loading && Network.network.reachable
        if loading != streamView.hidden {
            streamView.hidden = loading
            if loading {
                let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
                spinner.color = Color.orange
                self.spinner = spinner
                spinner.startAnimating()
            } else {
                spinner = nil
            }
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
            if Network.network.reachable {
                append(nil, failure: { $0?.showNonNetworkError() })
            } else {
                Network.network.subscribe(self, block: { [unowned self] reachable in
                    if reachable {
                        Network.network.unsubscribe(self)
                        if let streamView = self.streamView {
                            self.appendItemsIfNeededWithTargetContentOffset(streamView.contentOffset)
                        }
                    }
                })
            }
        }
    }
    
    override func didLayout() {
        super.didLayout()
        Dispatch.mainQueue.async { () -> Void in
            self.appendItemsIfNeededWithTargetContentOffset(self.streamView!.contentOffset)
        }
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        appendItemsIfNeededWithTargetContentOffset(targetContentOffset.memory)
    }
}
