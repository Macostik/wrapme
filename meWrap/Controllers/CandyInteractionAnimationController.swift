//
//  CandyInteractionAnimationController.swift
//  meWrap
//
//  Created by Yura Granchenko on 13/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

enum Direction {
    case Up
    case Down
    case Unknow
}

class CandyInteractionAnimationController: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {
    var navigationController: UINavigationController!
    var shouldCompleteTransition = false
    var transitionInProgress = false
    var speedCompletion: CGFloat = 0
    var percentComplition: CGFloat = 0
    
    var direction: Direction?  {
        didSet {
            if  (oldValue != direction && direction != .Unknow) {
//                cancelInteractiveTransition()
//                navigationController.popViewControllerAnimated(true)
            }
        }
    }
    
    static let sharedInstance = CandyInteractionAnimationController()
    
    func attachToViewController(viewController: UIViewController) {
        navigationController = viewController.navigationController
        setupGestureRecognizer(viewController.view)
    }
    
    private func setupGestureRecognizer(view: UIView) {
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "handlePanGesture:"))
    }
    
    func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        let viewTranslation = gestureRecognizer.translationInView(gestureRecognizer.view!.superview!)
        speedCompletion = gestureRecognizer.velocityInView(gestureRecognizer.view!.superview!).y
        switch gestureRecognizer.state {
        case .Began:
            transitionInProgress = true
            direction = speedCompletion < 0 ? .Up : .Down
            navigationController.popViewControllerAnimated(true)
        case .Changed:
            direction = speedCompletion < 0 ? .Up : .Down
            percentComplition = (viewTranslation.y / UIScreen.mainScreen().bounds.height)
            shouldCompleteTransition = fabs(percentComplition) > 0.7 || fabs(speedCompletion) > 1000
            updateInteractiveTransition(fabs(percentComplition))
        case .Cancelled, .Ended:
            transitionInProgress = false
            if !shouldCompleteTransition || gestureRecognizer.state == .Cancelled {
                cancelInteractiveTransition()
            } else {
                finishInteractiveTransition()
            }
        default: break
        }
    }
    
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 1.0
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) else {
                return
        }
        
        let finalFrame = transitionContext.finalFrameForViewController(toViewController)
        if let containerView = transitionContext.containerView() {
            toViewController.view.frame = finalFrame
            fromViewController.view.alpha = 1
            toViewController.view.alpha = 0
            containerView.addSubview(toViewController.view)
            containerView.sendSubviewToBack(toViewController.view)
            let screenBounds = UIScreen.mainScreen().bounds
            let fromFinalFrame = CGRectOffset(fromViewController.view.frame, 0, direction == .Up ? -screenBounds.size.height : screenBounds.size.height);
            let duration = self.transitionDuration(transitionContext)
            UIView.animateWithDuration(duration, animations: { () -> Void in
                fromViewController.view.frame = fromFinalFrame
                fromViewController.view.alpha = 0
                toViewController.view.alpha = 1
                }, completion: { Void in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
    }
}