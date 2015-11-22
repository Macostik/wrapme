//
//  StreamMetrics.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

class StreamMetrics: NSObject {
    
    convenience init(initializer: (StreamMetrics) -> Void) {
        self.init()
        self.change(initializer)
    }
    
    convenience init(identifier: String) {
        self.init()
        self.identifier = identifier
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
    
    @IBInspectable var identifier: String?
    
    var nib: UINib?
    
    @IBOutlet weak var nibOwner:AnyObject?
    
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
        
        if nib == nil {
            if let identifier = self.identifier {
                nib = UINib(nibName: identifier, bundle: nil)
            }
        }
        
        if let nib = self.nib {
            for object in nib.instantiateWithOwner(self.nibOwner, options: nil) {
                if let reusing = object as? StreamReusableView {
                    reusing.metrics = self
                    reusing.loadedWithMetrics(self)
                    return reusing
                }
            }
        }
        return nil
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