//
//  SwipeAction.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

private final class SwipeActioArrowView: ShapeView {
    override func defineShapePath(path: UIBezierPath, contentMode: UIViewContentMode) {
        let h = bounds.height
        let w = bounds.width
        if contentMode == .Left {
            path.move(0 ^ 0).line(0 ^ h).line(w - h/2.0 ^ h).line(w ^ h/2.0).line(w - h/2.0 ^ 0).line(0 ^ 0)
        } else if (contentMode == .Right) {
            path.move(w ^ 0).line(h/2.0 ^ 0).line(0 ^ h/2.0).line(h/2.0 ^ h).line(w ^ h).line(w ^ 0)
        }
    }
}

private final class SwipeActionView: UIView {
    
    let shape = SwipeActioArrowView()
    let icon = Label(icon: "", size: 24)
    let label = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    
    convenience init(isRight: Bool) {
        self.init()
        shape.contentMode = isRight ? .Right : .Left
        shape.clipsToBounds = true
        shape.backgroundColor = Color.orange
        addSubview(shape)
        addSubview(icon)
        addSubview(label)
        shape.snp_makeConstraints { $0.edges.equalTo(self) }
        icon.text = isRight ? ";" : "u"
        label.text = isRight ? "slide_to_chat".ls : "slide_to_open_camera".ls
        icon.snp_makeConstraints { (make) -> Void in
            if isRight {
                make.leading.equalTo(self).inset(25)
            } else {
                make.trailing.equalTo(self).inset(25)
            }
            make.centerY.equalTo(self)
        }
        label.snp_makeConstraints { (make) -> Void in
            if isRight {
                make.leading.equalTo(icon.snp_trailing).offset(10)
            } else {
                make.trailing.equalTo(icon.snp_leading).offset(-10)
            }
            make.centerY.equalTo(self)
        }
    }
}

var SwipeActionWidth: CGFloat = 125.0

enum SwipeActionDirection: Int {
    case Unknown, Right, Left
}

final class SwipeAction: NSObject {
    
    var direction: SwipeActionDirection = .Unknown
    
    var shouldBeginPanning: (SwipeAction -> Bool)?
    
    var didBeginPanning: (SwipeAction -> Void)?
    
    var didEndPanning: ((SwipeAction, Bool) -> Void)?
    
    var didPerformAction: ((SwipeAction, SwipeActionDirection) -> Void)?
    
    private var actionView: SwipeActionView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let actionView = actionView {
                view.addSubview(actionView)
                for subview in actionView.subviews {
                    subview.layoutIfNeeded()
                }
            }
        }
    }
    
    private weak var panGestureRecognizer: UIPanGestureRecognizer!
    
    private weak var view: UIView!
    
    private var translation: CGFloat = 0 {
        didSet {
            actionView?.transform = CGAffineTransformMakeTranslation(translation, 0)
        }
    }
    
    init(view: UIView) {
        super.init()
        self.view = view
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeAction.panning(_:)))
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
        panGestureRecognizer = recognizer
    }
    
    func panning(sender: UIPanGestureRecognizer) {
        
        switch sender.state {
        case .Began:
            view.backgroundColor = Color.grayLightest
            didBeginPanning?(self)
            if direction == .Right {
                let actionView = SwipeActionView(isRight: true)
                actionView.frame = view.bounds.offsetBy(dx: view.width, dy: 0)
                self.actionView = actionView
            } else if direction == .Left {
                let actionView = SwipeActionView(isRight: false)
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
            actionView?.icon.alpha = max(0.0, min(1.0, abs(translation)/SwipeActionWidth))
            actionView?.label.alpha = max(0.0, min(1.0, abs(translation)/SwipeActionWidth))
            break
        case .Ended, .Cancelled:
            let performedAction = abs(translation) >= SwipeActionWidth
            didEndPanning?(self, performedAction)
            if performedAction {
                performAction()
            } else if translation != 0 {
                cancelAction()
            } else {
                self.view.backgroundColor = UIColor.whiteColor()
            }
            break
        default: break
        }
    }
    
    func performAction() {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
            self.translation = (self.direction == .Right) ? -self.view.width : self.view.width
            }, completion: { (_) -> Void in
                self.view.backgroundColor = UIColor.whiteColor()
                self.didPerformAction?(self, self.direction)
                self.performSelector(#selector(SwipeAction.reset), withObject: nil, afterDelay: 0.5)
        })
    }
    
    func cancelAction() {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
            self.translation = 0
            }, completion: { _ in
                self.view.backgroundColor = UIColor.whiteColor()
                self.reset()
        })
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