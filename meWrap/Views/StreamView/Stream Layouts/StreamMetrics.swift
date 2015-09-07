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
    
    class func metrics(initializer: (StreamMetrics) -> Void) -> StreamMetrics {
        let metrics = self.init()
        metrics.change(initializer)
        return metrics
    }
    
    func change(initializer: (StreamMetrics) -> Void) -> StreamMetrics {
        initializer(self)
        return self
    }
    
    @IBInspectable var identifier: String?
    
    var nib: UINib?
    
    @IBOutlet weak var nibOwner:AnyObject?
    
    @IBInspectable var hidden: Bool = false
    
    var hiddenAt: (StreamIndex, StreamMetrics) -> Bool = { index, metrics in
        return metrics.hidden;
    }
    
    @IBInspectable var size: CGFloat = 0
    
    var sizeAt: (StreamIndex, StreamMetrics) -> CGFloat = { index, metrics in
        return metrics.size;
    }
    
    @IBInspectable var insets: CGRect = CGRectZero
    
    var insetsAt: (StreamIndex, StreamMetrics) -> CGRect = { index, metrics in
        return metrics.insets;
    }
    
    var selection: ((StreamItem?, AnyObject) -> Void)?
    
    var prepareAppearing: ((StreamItem?, AnyObject?) -> Void)?
    
    var finalizeAppearing: ((StreamItem?, AnyObject?) -> Void)?
    
    var reusableViews: Set<StreamReusableView> = Set()
    
    var adjustFrame = false
    
    func loadView () -> StreamReusableView? {
        
        if let view = reusableViews.first {
            reusableViews.remove(view)
            view.prepareForReuse()
            return view;
        }
        
        var nib = self.nib
        if nib == nil {
            if let identifier = self.identifier {
                nib = UINib(nibName: identifier, bundle: nil)
            }
        }
        if let objects = nib?.instantiateWithOwner(self.nibOwner, options: nil) {
            for object in objects {
                if let reusing = object as? StreamReusableView {
                    reusing.metrics = self
                    return reusing
                }
            }
        }
        
        return nil
    }
    
    func select(item:StreamItem?, entry:AnyObject) {
        if (selection != nil) {
            selection!(item, entry);
        }
    }
    
}