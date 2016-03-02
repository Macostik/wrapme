//
//  UIGestureRecognizer+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import ObjectiveC

typealias GestureAction = (UIGestureRecognizer) -> ()

private class GestureActionWrapper {
    var closure: GestureAction?
    init(_ closure: GestureAction?) {
        self.closure = closure
    }
}

private var identifierAssociationHandle: UInt8 = 0
private var actionClosureAssociationHandle: UInt8 = 1

extension UIGestureRecognizer {
    
    private var actionClosure: GestureAction? {
        get {
            if let wrapper = objc_getAssociatedObject(self, &actionClosureAssociationHandle) as? GestureActionWrapper {
                return wrapper.closure
            }
            return nil
        }
        set {
            let wrapper = GestureActionWrapper(newValue)
            objc_setAssociatedObject(self, &actionClosureAssociationHandle, wrapper, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    convenience init(view: UIView, closure: GestureAction) {
        self.init()
        addTarget(self, action: "action:")
        actionClosure = closure
        view.addGestureRecognizer(self)
    }
    
    func action(sender: UIGestureRecognizer) {
        actionClosure?(sender)
    }
}