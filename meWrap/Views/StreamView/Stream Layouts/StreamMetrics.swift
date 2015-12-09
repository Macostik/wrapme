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
    
    func loadView() -> StreamReusableView? {
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
    
    override func loadView() -> StreamReusableView? {
        return nib?.instantiateWithOwner(nibOwner, options: nil)[index] as? StreamReusableView
    }
    
    func loader(index: Int) -> IndexedStreamLoader {
        return IndexedStreamLoader(identifier: identifier, index: index)
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
    
    convenience init(initializer: (StreamMetrics) -> Void) {
        self.init()
        self.change(initializer)
    }
    
    convenience init(identifier: String) {
        self.init(loader: StreamLoader(identifier: identifier))
    }
    
    convenience init(identifier: String, initializer: (StreamMetrics) -> Void) {
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
    
    func change(initializer: (StreamMetrics) -> Void) -> StreamMetrics {
        initializer(self)
        return self
    }
    
    var loader = StreamLoader()
    
    @IBInspectable var identifier: String? {
        get {
            return loader.identifier
        }
        set {
            loader.identifier = newValue
        }
    }
    
    @IBOutlet weak var nibOwner:AnyObject? {
        get {
            return loader.nibOwner
        }
        set {
            loader.nibOwner = newValue
        }
    }
    
    @IBInspectable var hidden: Bool = false
    
    var hiddenAt: (StreamPosition, StreamMetrics) -> Bool = { index, metrics in
        return metrics.hidden
    }
    
    @IBInspectable var size: CGFloat = 0
    
    var sizeAt: (StreamPosition, StreamMetrics) -> CGFloat = { index, metrics in
        return metrics.size
    }
    
    @IBInspectable var insets: CGRect = CGRectZero
    
    var insetsAt: (StreamPosition, StreamMetrics) -> CGRect = { index, metrics in
        return metrics.insets
    }
    
    @IBInspectable var ratio: CGFloat = 0
    
    var isSeparator = false
    
    var ratioAt: (StreamPosition, StreamMetrics) -> CGFloat = { index, metrics in
        return metrics.ratio
    }
    
    var selectable = true
    
    var selection: ((StreamItem?, AnyObject?) -> Void)?
    
    var prepareAppearing: ((StreamItem?, AnyObject?) -> Void)?
    
    var finalizeAppearing: ((StreamItem?, AnyObject?) -> Void)?
    
    var reusableViews: Set<StreamReusableView> = Set()
    
    var disableMenu = false
    
    func loadView () -> StreamReusableView? {
        if let reusing = loader.loadView() {
            reusing.metrics = self
            reusing.loadedWithMetrics(self)
            return reusing
        } else {
            return nil
        }
    }
    
    func dequeueView() -> StreamReusableView? {
        if let view = reusableViews.first {
            reusableViews.remove(view)
            view.didDequeue()
            return view
        }
        return loadView()
    }
    
    func dequeueViewWithItem(item: StreamItem) -> StreamReusableView? {
        if let view = dequeueView() {
            view.item = item
            UIView.performWithoutAnimation({ () -> Void in
                view.frame = item.frame
            })
            item.view = view
            let entry: AnyObject? = item.entry
            prepareAppearing?(item, entry)
            view.entry = entry
            finalizeAppearing?(item, entry)
            return view
        }
        return nil
    }
    
    func enqueueView(view: StreamReusableView) {
        view.willEnqueue()
        reusableViews.insert(view)
    }
    
    func select(item: StreamItem?, entry: AnyObject?) {
        if (selection != nil) {
            selection!(item, entry)
        }
    }
    
}