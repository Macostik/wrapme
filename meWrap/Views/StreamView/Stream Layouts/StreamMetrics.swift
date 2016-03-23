//
//  StreamMetrics.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

protocol StreamLoaderType {
    func loadView() -> StreamReusableView?
}

struct StreamLoader<T: StreamReusableView>: StreamLoaderType {
    
    var layoutBlock: (T -> Void)?
    
    init(layoutBlock: (T -> Void)? = nil) {
        self.layoutBlock = layoutBlock
    }
    
    func loadView() -> StreamReusableView? {
        let view = T()
        layoutBlock?(view)
        return view
    }
}

final class StreamMetrics {
    
    init(loader: StreamLoaderType, size: CGFloat = 0) {
        self.loader = loader
        self.size = size
    }
    
    func change(@noescape initializer: (StreamMetrics) -> Void) -> StreamMetrics {
        initializer(self)
        return self
    }
    
    var loader: StreamLoaderType
    
    var modifyItem: (StreamItem -> Void)?
    
    var hidden: Bool = false
    var size: CGFloat = 0
    var insets: CGRect = CGRectZero
    var ratio: CGFloat = 0
    
    var isSeparator = false
    
    var selectable = true
    
    var selection: ((StreamItem?, AnyObject?) -> Void)?
    
    var prepareAppearing: ((StreamItem, StreamReusableView) -> Void)?
    
    var finalizeAppearing: ((StreamItem, StreamReusableView) -> Void)?
    
    var reusableViews: Set<StreamReusableView> = Set()
    
    var disableMenu = false
    
    func loadView() -> StreamReusableView? {
        if let reusing = loader.loadView() {
            reusing.metrics = self
            reusing.didLoad()
            reusing.layoutWithMetrics(self)
            return reusing
        } else {
            return nil
        }
    }
    
    func findView(item: StreamItem) -> StreamReusableView? {
        for view in reusableViews where view.item?.entry === item.entry {
            return view
        }
        return reusableViews.first
    }
    
    func dequeueView(item: StreamItem) -> StreamReusableView? {
        if let view = findView(item) {
            reusableViews.remove(view)
            view.didDequeue()
            return view
        }
        return loadView()
    }
    
    func dequeueViewWithItem(item: StreamItem) -> StreamReusableView? {
        if let view = dequeueView(item) {
            view.item = item
            UIView.performWithoutAnimation { view.frame = item.frame }
            item.view = view
            prepareAppearing?(item, view)
            view.entry = item.entry
            finalizeAppearing?(item, view)
            return view
        }
        return nil
    }
    
    func enqueueView(view: StreamReusableView) {
        view.willEnqueue()
        reusableViews.insert(view)
    }
    
    func select(item: StreamItem?, entry: AnyObject?) {
        selection?(item, entry)
    }
}