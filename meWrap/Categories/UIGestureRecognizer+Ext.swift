//
//  UIGestureRecognizer+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import ObjectiveC

extension UIView {
    func removeGestureRecognizerWithIdentifier(identifier: String) {
        guard let gestureRecognizers = gestureRecognizers else {
            return
        }
        for recognizer in gestureRecognizers {
            if recognizer.identifier == identifier {
                removeGestureRecognizer(recognizer)
            }
        }
    }
}

typealias GestureAction = (UIGestureRecognizer) -> ()

class GestureActionWrapper {
    var closure: GestureAction?
    
    init(_ closure: GestureAction?) {
        self.closure = closure
    }
}

private var identifierAssociationHandle: UInt8 = 0
private var actionClosureAssociationHandle: UInt8 = 1

extension UIGestureRecognizer {
    
    var identifier: String? {
        get {
            return objc_getAssociatedObject(self, &identifierAssociationHandle) as? String
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, &identifierAssociationHandle, value, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    var actionClosure: GestureAction? {
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
    
    convenience init(view: UIView) {
        self.init(view: view, identifier: nil, closure: nil)
    }
    
    convenience init(view: UIView, closure: GestureAction?) {
        self.init(view: view, identifier: nil, closure: closure)
    }
    
    convenience init(view: UIView, identifier: String?, closure: GestureAction?) {
        self.init()
        addTarget(self, action: "action:")
        if let closure = closure {
            actionClosure = closure
        }
        if let identifier = identifier {
            self.identifier = identifier
        }
        view.addGestureRecognizer(self)
    }
    
    func action(sender: UIGestureRecognizer) {
        actionClosure?(sender)
    }
}