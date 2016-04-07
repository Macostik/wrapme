//
//  UIGestureRecognizer+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

protocol Gesture {
    init(closure: Self -> ())
    var actionClosure: (Self -> ())? { get set }
    func addTo(view: UIView) -> Self
    func remove()
}

extension UIGestureRecognizer {
    
    func addTo(view: UIView) -> Self {
        view.addGestureRecognizer(self)
        return self
    }
    
    func remove() {
        view?.removeGestureRecognizer(self)
    }
}

extension UIView {
    
    func tapped(closure: (TapGesture -> ())) -> TapGesture {
        return recognize(closure)
    }
    
    func panned(closure: (PanGesture -> ())) -> PanGesture {
        return recognize(closure)
    }
    
    func swiped(closure: (SwipeGesture -> ())) -> SwipeGesture {
        return recognize(closure)
    }
    
    func recognize<T: Gesture>(closure: T -> ()) -> T {
        return T(closure: closure).addTo(self)
    }
}

final class TapGesture: UITapGestureRecognizer, Gesture {
    
    convenience init(closure: TapGesture -> ()) {
        self.init()
        addTarget(self, action: #selector(self.action(_:)))
        actionClosure = closure
    }
    
    var actionClosure: (TapGesture -> ())?
    
    func action(sender: TapGesture) {
        actionClosure?(self)
    }
}

final class PanGesture: UIPanGestureRecognizer, Gesture {
    
    convenience init(closure: PanGesture -> ()) {
        self.init()
        addTarget(self, action: #selector(self.action(_:)))
        actionClosure = closure
    }
    
    var actionClosure: (PanGesture -> ())?
    
    func action(sender: PanGesture) {
        actionClosure?(sender)
    }
}

final class SwipeGesture: UISwipeGestureRecognizer, Gesture {
    
    convenience init(closure: SwipeGesture -> ()) {
        self.init()
        addTarget(self, action: #selector(self.action(_:)))
        actionClosure = closure
    }
    
    var actionClosure: (SwipeGesture -> ())?
    
    func action(sender: SwipeGesture) {
        actionClosure?(sender)
    }
}