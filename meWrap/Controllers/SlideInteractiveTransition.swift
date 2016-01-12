//
//  SlideInteractiveTransition.swift
//  meWrap
//
//  Created by Yura Granchenko on 18/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol SlideInteractiveTransitionDelegate {
    
    optional func slideInteractiveTransition(controller: SlideInteractiveTransition, hideViews: Bool)
    
    optional func slideInteractiveTransitionDidFinish(controller: SlideInteractiveTransition)
    
    optional func slideInteractiveTransitionSnapshotView(controller: SlideInteractiveTransition) -> UIView?
}

class SlideInteractiveTransition: NSObject, UIGestureRecognizerDelegate {

    weak var delegate: SlideInteractiveTransitionDelegate?
    
    private weak var screenShotView: UIView?
    private weak var contentView: UIView!
    lazy var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
    
    required init (contentView: UIView) {
        self.contentView = contentView
        super.init()
        panGestureRecognizer.delegate = self
        contentView.addGestureRecognizer(panGestureRecognizer)
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer) {
        guard let superview = contentView.superview else { return }
        let translation = gesture.translationInView(superview).y
        let percentCompleted = abs(translation/superview.height)
        switch gesture.state {
        case .Began:
            addScreenShotView()
            delegate?.slideInteractiveTransition?(self, hideViews: true)
        case .Changed:
            contentView.transform = CGAffineTransformMakeTranslation(0, translation)
            screenShotView?.alpha = percentCompleted
        case .Ended, .Cancelled:
            if  (percentCompleted > 0.25 || abs(gesture.velocityInView(superview).y) > 1000) {
                let endPoint = superview.height
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.screenShotView?.alpha = 1
                    self.contentView.transform = CGAffineTransformMakeTranslation(0, translation <= 0 ? -endPoint : endPoint)
                    }, completion: { (finished) -> Void in
                        self.delegate?.slideInteractiveTransitionDidFinish?(self)
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                     self.contentView.transform = CGAffineTransformIdentity
                    }, completion: { (finished) -> Void in
                        self.screenShotView?.removeFromSuperview()
                        self.delegate?.slideInteractiveTransition?(self, hideViews: false)
                })
            }
        default:break
        }
    }
    
    private func snapshotView() -> UIView? {
        return delegate?.slideInteractiveTransitionSnapshotView?(self)
    }
    
    private func addScreenShotView () {
        if let screenShotView = snapshotView()?.snapshotViewAfterScreenUpdates(true) {
            screenShotView.alpha = 0
            switch DeviceManager.defaultManager.orientation {
            case .LandscapeLeft:
                screenShotView.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2));
                break
            case .LandscapeRight:
                screenShotView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
                break
            default: break
            }
            screenShotView.frame = UIScreen.mainScreen().bounds
            contentView.superview?.insertSubview(screenShotView, belowSubview: contentView)
            self.screenShotView = screenShotView
        }
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if panGestureRecognizer == gestureRecognizer {
            let velocity = panGestureRecognizer.velocityInView(contentView)
            return abs(velocity.x) < abs(velocity.y)
        } else {
            return true
        }
    }
}