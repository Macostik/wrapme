//
//  UIGestureRecognizer+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

final class GestureRecognizer<T: UIGestureRecognizer> {
    
    private var actionClosure: (T -> ())?
    
    private var gestureRecognizer: T?
    
    init(view: UIView, closure: T -> ()) {
        let gestureRecognizer = T(target: self, action: #selector(GestureRecognizer.action(_:)))
        actionClosure = closure
        view.addGestureRecognizer(gestureRecognizer)
        self.gestureRecognizer = gestureRecognizer
    }
    
    @objc func action(sender: AnyObject) {
        if let sender = gestureRecognizer {
            actionClosure?(sender)
        }
    }
}