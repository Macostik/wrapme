//
//  CandyInteractionController.swift
//  meWrap
//
//  Created by Yura Granchenko on 18/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class CandyInteractionController: NSObject, UIGestureRecognizerDelegate {

    var screenShotView: UIView?
    var isMoveUp: Bool = false
    var contentView: UIView
    var currentViewController: WLHistoryViewController
    var allowGesture = true
    private var panGesture: UIPanGestureRecognizer?
    
    required init (viewController: WLHistoryViewController) {
        currentViewController = viewController
        if let contentView = viewController.contentView {
            self.contentView = contentView
        } else {
            contentView = viewController.view
        }
        super.init()
        setup()
    }
    
    func setup () {
        panGesture = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        panGesture!.delegate = self
        contentView.addGestureRecognizer(panGesture!)
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer) {
        if (!allowGesture) { return }
        let translationPoint = gesture.translationInView(contentView)
        let velocity = gesture.velocityInView(contentView)
        let percentCompleted = abs(translationPoint.y/self.contentView.height)
        switch gesture.state {
        case .Began:
            isMoveUp = velocity.y < 0
            addSplashScreenToHierarchy()
            setSecondaryVeiwHidden(true, animated: true)
        case .Changed:
            UIView.animateWithDuration(0.0, animations: { [weak self]  () -> Void in
                self!.contentView.transform = CGAffineTransformMakeTranslation(0, translationPoint.y)
                self!.screenShotView?.alpha = percentCompleted
            })
        case .Ended:
            if  (percentCompleted > 0.5 || abs(velocity.y) > 1000) {
                currentViewController.navigationController?.popViewControllerAnimated(false)
            } else {
                UIView.animateWithDuration(0.25, animations: { [weak self] () -> Void in
                     self!.contentView.transform = CGAffineTransformIdentity
                    }, completion: { (finished) -> Void in
                        self.screenShotView?.removeFromSuperview()
                        self.setSecondaryVeiwHidden(false, animated: true)
                })
            }
        default:
            UIView.animateWithDuration(0.25, animations: { [weak self] () -> Void in
                self!.contentView.transform = CGAffineTransformIdentity
                }, completion: { (finished) -> Void in
                    self.screenShotView?.removeFromSuperview()
                    self.setSecondaryVeiwHidden(false, animated: true)
            })
            break
        }
    }
    
    func presentingViewController() -> UIViewController? {
        let viewControllers: NSArray = (currentViewController.navigationController?.viewControllers)!
        let ownerIndex = viewControllers.indexOfObject(currentViewController)
        if  (0 < ownerIndex) {
            let presentingViewController = viewControllers.objectAtIndex(ownerIndex - 1) as! UIViewController
            return presentingViewController
        }
        return nil
    }
    
    func setSecondaryVeiwHidden(hidden: Bool, animated: Bool) {
        currentViewController.scrollView?.alwaysBounceHorizontal = !hidden
        currentViewController.setBarsHidden(hidden, animated: animated)
        currentViewController.commentButtonPrioritizer?.defaultState = !hidden
    }
    
    func addSplashScreenToHierarchy () {
        screenShotView = presentingViewController()?.view.snapshotViewAfterScreenUpdates(true)
        screenShotView?.frame = contentView.frame
        screenShotView?.alpha = 0
        currentViewController.view.insertSubview(screenShotView!, belowSubview: contentView)
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = panGesture?.velocityInView(contentView)
        return panGesture! == gestureRecognizer && abs(velocity!.x) < abs(velocity!.y)
    }
}