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

typealias GestureAction = @convention(block) (UIGestureRecognizer) -> ()

class GestureActionWrapper {
    var closure: GestureAction?
    
    init(_ closure: GestureAction?) {
        self.closure = closure
    }
}

extension UIGestureRecognizer {
    
    var identifier: String? {
        get {
            return objc_getAssociatedObject(self, "identifier") as? String
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, "identifier", value, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    var actionClosure: GestureAction? {
        get {
            return (objc_getAssociatedObject(self, "actionClosure") as? GestureActionWrapper)?.closure
        }
        set {
            objc_setAssociatedObject(self, "actionClosure", GestureActionWrapper(newValue), .OBJC_ASSOCIATION_RETAIN)
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