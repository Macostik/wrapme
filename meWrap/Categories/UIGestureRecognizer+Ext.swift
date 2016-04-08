//
//  UIGestureRecognizer+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

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
        return TapGesture(closure: closure).addTo(self)
    }
    
    func panned(closure: (PanGesture -> ())) -> PanGesture {
        return PanGesture(closure: closure).addTo(self)
    }
    
    func swiped(direction: UISwipeGestureRecognizerDirection, closure: (SwipeGesture -> ())) -> SwipeGesture {
        return SwipeGesture(direction: direction, closure: closure).addTo(self)
    }
}

final class TapGesture: UITapGestureRecognizer {
    
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

final class PanGesture: UIPanGestureRecognizer {
    
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

final class SwipeGesture: UISwipeGestureRecognizer {
    
    convenience init(direction: UISwipeGestureRecognizerDirection, closure: SwipeGesture -> ()) {
        self.init()
        self.direction = direction
        addTarget(self, action: #selector(self.action(_:)))
        actionClosure = closure
    }
    
    var actionClosure: (SwipeGesture -> ())?
    
    func action(sender: SwipeGesture) {
        actionClosure?(sender)
    }
}