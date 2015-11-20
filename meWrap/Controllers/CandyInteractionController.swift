//
//  CandyInteractionController.swift
//  meWrap
//
//  Created by Yura Granchenko on 18/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class CandyInteractionController: NSObject, UIGestureRecognizerDelegate {

    weak var screenShotView: UIView?
    var isMoveUp: Bool = false
    unowned var contentView: UIView
    unowned var currentViewController: WLHistoryViewController
    var allowGesture = true
    lazy var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
    
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
        panGesture.delegate = self
        contentView.addGestureRecognizer(panGesture)
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer) {
        if (!allowGesture) { return }
        let translationPoint = gesture.translationInView(contentView)
        let velocity = gesture.velocityInView(contentView)
        let percentCompleted = abs(translationPoint.y/self.contentView.height)
        isMoveUp = velocity.y < 0
        switch gesture.state {
        case .Began:
            addSplashScreenToHierarchy()
            setSecondaryVeiwHidden(true, animated: true)
            applyDeviceToOrientation(WLDeviceManager.defaultManager().orientation)
        case .Changed:
            UIView.performAnimated(true, animation: { () -> (Void) in
                self.contentView.transform = CGAffineTransformMakeTranslation(0, translationPoint.y)
            })
            self.screenShotView?.alpha = percentCompleted
        case .Ended, .Cancelled:
            if  (percentCompleted > 0.5 || abs(velocity.y) > 1000) {
                let endPoint = contentView.height
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.screenShotView?.alpha = 1
                    self.contentView.transform = CGAffineTransformMakeTranslation(0, self.isMoveUp ? -endPoint : endPoint)
                    }, completion: { (finished) -> Void in
                        self.currentViewController.navigationController?.popViewControllerAnimated(false)
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { [weak self] () -> Void in
                     self!.contentView.transform = CGAffineTransformIdentity
                    }, completion: { (finished) -> Void in
                        self.screenShotView?.removeFromSuperview()
                        self.setSecondaryVeiwHidden(false, animated: true)
                })
            }
        default:break
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
        if let screenShotView = presentingViewController()?.view.snapshotViewAfterScreenUpdates(true) {
            screenShotView.alpha = 0
            currentViewController.view.insertSubview(screenShotView, belowSubview: contentView)
            self.screenShotView = screenShotView
        }
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = panGesture.velocityInView(contentView)
        return panGesture == gestureRecognizer && abs(velocity.x) < abs(velocity.y)
    }
    
    func applyDeviceToOrientation(orientation: UIDeviceOrientation) {
        var transform = CGAffineTransformIdentity
        switch (orientation) {
        case .LandscapeLeft:
            transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2));
            break;
        case .LandscapeRight:
            transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
            break;
        default:
            break;
        }
        UIView.performWithoutAnimation { () -> Void in
            self.screenShotView?.transform = transform
            self.screenShotView?.frame = UIScreen.mainScreen().bounds
        }
    }
}