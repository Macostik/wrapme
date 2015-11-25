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
    var vectorUp = true
    weak var contentView: UIView!
    unowned var currentViewController: WLCandyViewController
    var allowGesture = true
    lazy var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
    var interactionHandler: ((Bool) -> Void)
    
    required init (viewController: WLCandyViewController, interactionHandler:(Bool) -> Void) {
        currentViewController = viewController
        self.contentView = viewController.contentView
        self.interactionHandler = interactionHandler
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
        isMoveUp = velocity.y <= 0
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
            if (velocity.y != 0) { vectorUp = velocity.y < 0 }
        case .Ended, .Cancelled:
            if  (percentCompleted > 0.5 || abs(velocity.y) > 1000) {
                let endPoint = contentView.height
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.screenShotView?.alpha = 1
                    print (">>self - \(self.isMoveUp) - \(self.vectorUp)<<")
                    self.contentView.transform = CGAffineTransformMakeTranslation(0, self.isMoveUp && self.vectorUp ? -endPoint : endPoint)
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
        let presentingViewController = currentViewController.parentViewController ?? currentViewController.presentedViewController ?? currentViewController
        let ownerIndex = viewControllers.indexOfObject(presentingViewController)
        if  (0 < ownerIndex) {
            let presentingViewController = viewControllers.objectAtIndex(ownerIndex - 1) as! UIViewController
            return presentingViewController
        }
        return nil
    }
    
    func setSecondaryVeiwHidden(hidden: Bool, animated: Bool) {
        if let interactionHandler: (Bool) -> Void = interactionHandler {
            interactionHandler(hidden)
        }
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