//
//  StreamMetrics.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

protocol StreamMetricsProtocol: class {
    func enqueueView(view: StreamReusableView)
    func dequeueViewWithItem(item: StreamItem) -> StreamReusableView
    func loadView() -> StreamReusableView
    var hidden: Bool { get set }
    var size: CGFloat { get set }
    var insets: CGRect { get set }
    var ratio: CGFloat { get set }
    var selectable: Bool { get }
    var modifyItem: (StreamItem -> Void)? { get }
    func select(view: StreamReusableView)
    var disableMenu: Bool { get }
    var isSeparator: Bool { get set }
}

class StreamMetrics<T: StreamReusableView>: StreamMetricsProtocol {
    
    init(layoutBlock: (T -> Void)? = nil, size: CGFloat = 0) {
        self.layoutBlock = layoutBlock
        self.size = size
    }
    
    func change(@noescape initializer: (StreamMetrics) -> Void) -> StreamMetrics {
        initializer(self)
        return self
    }
    
    var layoutBlock: (T -> Void)?
    
    var modifyItem: (StreamItem -> Void)?
    
    var hidden: Bool = false
    var size: CGFloat = 0
    var insets: CGRect = CGRectZero
    var ratio: CGFloat = 0
    
    var isSeparator = false
    
    var selectable = true
    
    var selection: (T -> Void)?
    
    var prepareAppearing: ((StreamItem, T) -> Void)?
    
    var finalizeAppearing: ((StreamItem, T) -> Void)?
    
    var reusableViews: Set<T> = Set()
    
    var disableMenu = false
    
    func loadView() -> StreamReusableView {
        let view = T()
        layoutBlock?(view)
        view.metrics = self
        view.didLoad()
        view.layoutWithMetrics(self)
        return view
    }
    
    func findView(item: StreamItem) -> T? {
        for view in reusableViews where view.item?.entry === item.entry {
            return view
        }
        return reusableViews.first
    }
    
    func dequeueView(item: StreamItem) -> T {
        if let view = findView(item) {
            reusableViews.remove(view)
            view.didDequeue()
            return view
        }
        return loadView() as! T
    }
    
    func dequeueViewWithItem(item: StreamItem) -> StreamReusableView {
        let view = dequeueView(item)
        view.item = item
        UIView.performWithoutAnimation { view.frame = item.frame }
        item.view = view
        prepareAppearing?(item, view)
        view.entry = item.entry
        finalizeAppearing?(item, view)
        return view
    }
    
    func enqueueView(view: StreamReusableView) {
        if let view = view as? T {
            view.willEnqueue()
            reusableViews.insert(view)
        }
    }
    
    func select(view: StreamReusableView) {
        if let view = view as? T {
            selection?(view)
        }
    }
}