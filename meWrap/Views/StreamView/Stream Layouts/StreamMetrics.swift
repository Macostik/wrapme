//
//  StreamMetrics.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

class StreamLoader: NSObject {
    
    var identifier: String?
    
    private var _nib: UINib?
    var nib: UINib? {
        if _nib == nil {
            if let identifier = identifier {
                _nib = UINib(nibName: identifier, bundle: nil)
            }
        }
        return _nib
    }
    
    weak var nibOwner:AnyObject?
    
    func loadView(metrics: StreamMetrics) -> StreamReusableView? {
        if let nib = nib {
            for object in nib.instantiateWithOwner(nibOwner, options: nil) {
                if let reusing = object as? StreamReusableView {
                    return reusing
                }
            }
        }
        return nil
    }
    
    convenience init(identifier: String?) {
        self.init()
        self.identifier = identifier
    }
}

class IndexedStreamLoader: StreamLoader {
    
    var index: Int = 0
    
    convenience init(identifier: String?, index: Int) {
        self.init(identifier: identifier)
        self.index = index
    }
    
    override func loadView(metrics: StreamMetrics) -> StreamReusableView? {
        return nib?.instantiateWithOwner(nibOwner, options: nil)[index] as? StreamReusableView
    }
    
    func loader(index: Int) -> IndexedStreamLoader {
        return IndexedStreamLoader(identifier: identifier, index: index)
    }
}

class LayoutStreamLoader<T: StreamReusableView>: StreamLoader {
    
    var layoutBlock: (T -> Void)?
    
    convenience init(layoutBlock: (T -> Void)?) {
        self.init()
        self.layoutBlock = layoutBlock
    }
    
    override func loadView(metrics: StreamMetrics) -> StreamReusableView? {
        let view = T()
        layoutBlock?(view)
        view.layoutWithMetrics(metrics)
        return view
    }
}

class StreamMetrics: NSObject {
    
    convenience init(loader: StreamLoader, size: CGFloat) {
        self.init(loader: loader)
        self.size = size
    }
    
    convenience init(loader: StreamLoader) {
        self.init()
        self.loader = loader
    }
    
    convenience init(@noescape initializer: (StreamMetrics) -> Void) {
        self.init()
        self.change(initializer)
    }
    
    convenience init(identifier: String) {
        self.init(loader: StreamLoader(identifier: identifier))
    }
    
    convenience init(identifier: String, @noescape initializer: (StreamMetrics) -> Void) {
        self.init(identifier: identifier)
        self.change(initializer)
    }
    
    convenience init(identifier: String, size: CGFloat) {
        self.init(identifier: identifier)
        self.size = size
    }
    
    convenience init(identifier: String, ratio: CGFloat) {
        self.init(identifier: identifier)
        self.ratio = ratio
    }
    
    func change(@noescape initializer: (StreamMetrics) -> Void) -> StreamMetrics {
        initializer(self)
        return self
    }
    
    var loader = StreamLoader()
    
    var identifier: String? {
        get { return loader.identifier }
        set { loader.identifier = newValue }
    }
    
    weak var nibOwner:AnyObject? {
        get { return loader.nibOwner }
        set { loader.nibOwner = newValue }
    }
    
    var hidden: Bool = false
    
    var hiddenAt: StreamItem -> Bool = { $0.metrics.hidden }
    
    var size: CGFloat = 0
    
    var sizeAt: StreamItem -> CGFloat = {  $0.metrics.size }
    
    var insets: CGRect = CGRectZero
    
    var insetsAt: StreamItem -> CGRect = { $0.metrics.insets }
    
    var ratio: CGFloat = 0
    
    var isSeparator = false
    
    var ratioAt: StreamItem -> CGFloat = { $0.metrics.ratio }
    
    var selectable = true
    
    var selection: ((StreamItem?, AnyObject?) -> Void)?
    
    var prepareAppearing: ((StreamItem, StreamReusableView) -> Void)?
    
    var finalizeAppearing: ((StreamItem, StreamReusableView) -> Void)?
    
    var reusableViews: Set<StreamReusableView> = Set()
    
    var disableMenu = false
    
    func loadView () -> StreamReusableView? {
        if let reusing = loader.loadView(self) {
            reusing.metrics = self
            reusing.loadedWithMetrics(self)
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