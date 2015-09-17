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
    
    func change(initializer: (StreamMetrics) -> Void) -> StreamMetrics {
        initializer(self)
        return self
    }
    
    @IBInspectable var identifier: String?
    
    var nib: UINib?
    
    @IBOutlet weak var nibOwner:AnyObject?
    
    @IBInspectable var hidden: Bool = false
    
    var hiddenAt: (StreamPosition, StreamMetrics) -> Bool = { index, metrics in
        return metrics.hidden;
    }
    
    @IBInspectable var size: CGFloat = 0
    
    var sizeAt: (StreamPosition, StreamMetrics) -> CGFloat = { index, metrics in
        return metrics.size;
    }
    
    @IBInspectable var insets: CGRect = CGRectZero
    
    var insetsAt: (StreamPosition, StreamMetrics) -> CGRect = { index, metrics in
        return metrics.insets;
    }
    
    var selection: ((StreamItem?, AnyObject?) -> Void)?
    
    var prepareAppearing: ((StreamItem?, AnyObject?) -> Void)?
    
    var finalizeAppearing: ((StreamItem?, AnyObject?) -> Void)?
    
    var reusableViews: Set<StreamReusableView> = Set()
    
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
                    return reusing
                }
            }
        }
        return nil
    }
    
    func dequeueView() -> StreamReusableView? {
        if let view = reusableViews.first {
            reusableViews.remove(view)
            view.prepareForReuse()
            return view;
        }
        return loadView()
    }
    
    func dequeueViewWithItem(item: StreamItem) -> StreamReusableView? {
        if let view = dequeueView() {
            view.item = item
            view.frame = item.frame
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
        reusableViews.insert(view)
    }
    
    func select(item: StreamItem?, entry: AnyObject?) {
        if (selection != nil) {
            selection!(item, entry);
        }
    }
    
}