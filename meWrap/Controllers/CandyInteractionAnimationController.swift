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
    var disablePan = false
    var speedCompletion: CGFloat = 0
    var percentComplition: CGFloat = 0
    var toViewController: UIViewController?
    var fromViewController: UIViewController?
    var direction: Direction?
    var handlePanGesture: ((CGPoint)->(Void))?
    
    func attachToViewController(viewController: UIViewController) {
        navigationController = viewController.navigationController
        setupGestureRecognizer(viewController.view)
    }
    
    private func setupGestureRecognizer(view: UIView) {
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "handlePanGesture:"))
    }
    
    func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        if  (disablePan) { return }
        let viewTranslation = gestureRecognizer.translationInView(gestureRecognizer.view!.superview!)
        speedCompletion = gestureRecognizer.velocityInView(gestureRecognizer.view!.superview!).y
        switch gestureRecognizer.state {
        case .Began:
            transitionInProgress = true
            direction = speedCompletion < 0 ? .Up : .Down
            navigationController.popViewControllerAnimated(true)
        case .Changed:
            percentComplition = (viewTranslation.y / UIScreen.mainScreen().bounds.height)
            if let handlePanGesture: (CGPoint) -> Void? = handlePanGesture {
                handlePanGesture(viewTranslation)
            }
            shouldCompleteTransition = fabs(percentComplition) > 0.5 || fabs(speedCompletion) > 1000
            updateInteractiveTransition(fabs(percentComplition) / 0.5)
        case .Cancelled, .Ended:
            transitionInProgress = false
            fromViewController?.view.alpha = 0
            toViewController?.view.alpha = 1
            if !shouldCompleteTransition || gestureRecognizer.state == .Cancelled {
                cancelInteractiveTransition()
            } else {
                finishInteractiveTransition()
            }
        default: break
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.1
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        if let toViewController = toViewController, let fromViewController = fromViewController {
            let finalFrame = transitionContext.finalFrameForViewController(toViewController)
            if let containerView = transitionContext.containerView() {
                toViewController.view.frame = finalFrame
                fromViewController.view.alpha = 1
                toViewController.view.alpha = 0
                containerView.addSubview(toViewController.view)
                containerView.sendSubviewToBack(toViewController.view)
                let duration = self.transitionDuration(transitionContext)
                UIView.animateWithDuration(duration, animations: { () -> Void in
                    fromViewController.view.alpha = 0
                    toViewController.view.alpha = 1
                    }, completion: { Void in
                        toViewController.view.alpha = 1
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                })
            }
        }
    }
}