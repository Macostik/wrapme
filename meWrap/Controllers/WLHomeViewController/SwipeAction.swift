//
//  SwipeAction.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

var SwipeActionWidth: CGFloat = 125.0

enum SwipeActionDirection: Int {
    case Unknown, Right, Left
}

class SwipeAction: NSObject {
    
    var direction: SwipeActionDirection = .Unknown
    
    var shouldBeginPanning: (SwipeAction -> Bool)?
    
    var didBeginPanning: (SwipeAction -> Void)?
    
    var didEndPanning: ((SwipeAction, Bool) -> Void)?
    
    var didPerformAction: ((SwipeAction, SwipeActionDirection) -> Void)?
    
    var actionView: UIView? {
        didSet {
            if let actionView = oldValue {
                actionView.removeFromSuperview()
            }
            if let actionView = actionView {
                view.addSubview(actionView)
            }
        }
    }
    
    @IBOutlet var indicators: [UIView] = []
    
    weak var panGestureRecognizer: UIPanGestureRecognizer!
    
    weak var view: UIView!
    
    var translation: CGFloat = 0 {
        didSet {
            actionView?.transform = CGAffineTransformMakeTranslation(translation, 0)
        }
    }
    
    init(view: UIView) {
        super.init()
        self.view = view
        let recognizer = UIPanGestureRecognizer(target: self, action: "panning:")
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
        panGestureRecognizer = recognizer
    }
    
    func panning(sender: UIPanGestureRecognizer) {
        
        switch sender.state {
        case .Began:
            didBeginPanning?(self)
            if direction == .Right {
                let actionView = NSBundle.mainBundle().loadNibNamed("RightSwipeActionView", owner: self, options: nil).first as! UIView
                actionView.frame = view.bounds.offsetBy(dx: view.width, dy: 0)
                self.actionView = actionView
            } else if direction == .Left {
                let actionView = NSBundle.mainBundle().loadNibNamed("LeftSwipeActionView", owner: self, options: nil).first as! UIView
                actionView.frame = view.bounds.offsetBy(dx: -view.width, dy: 0)
                self.actionView = actionView
            }
            break
        case .Changed:
            var translation = sender.translationInView(view).x
            if direction == .Right {
                translation = max(-view.width, min(0, translation))
            } else if direction == .Left {
                translation = max(0, min(view.width, translation))
            }
            self.translation = translation
            for indicator in indicators {
                indicator.alpha = max(0.0, min(1.0, abs(translation)/SwipeActionWidth))
            }
            break
        case .Ended, .Cancelled:
            let performedAction = abs(translation) >= SwipeActionWidth
            didEndPanning?(self, performedAction)
            if performedAction {
                performAction()
            } else if translation != 0 {
                cancelAction()
            }
            break
        default: break
        }
    }
    
    func performAction() {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
            self.translation = (self.direction == .Right) ? -self.view.width : self.view.width
            }, completion: { (_) -> Void in
                self.didPerformAction?(self, self.direction)
                self.performSelector("reset", withObject: nil, afterDelay: 0.5)
        })
    }
    
    func cancelAction() {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
            self.reset()
            }, completion: nil)
    }
    
    func reset() {
        actionView = nil
    }
}

extension SwipeAction: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if panGestureRecognizer == gestureRecognizer {
            let velocity = panGestureRecognizer.velocityInView(gestureRecognizer.view)
            let shouldBegin = abs(velocity.x) > abs(velocity.y)
            direction = velocity.x < 0 ? .Right : .Left
            if (shouldBegin) {
                return shouldBeginPanning?(self) ?? false
            }
            return shouldBegin
        }
        return true
    }
}