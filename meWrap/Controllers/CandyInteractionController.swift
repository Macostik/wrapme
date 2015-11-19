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
    var currentViewController: UIViewController
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
        if (abs(velocity.x) > 0) { return }
        switch gesture.state {
        case .Began:
            isMoveUp = velocity.y < 0
            addSplashScreenToHierarchy()
        case .Changed:
            UIView.performAnimated(true, animation: { () -> (Void) in
                self.contentView.transform = CGAffineTransformMakeTranslation(0, translationPoint.y)
                self.screenShotView?.alpha = abs(translationPoint.y/self.contentView.height)
            })
            
        case .Cancelled, .Ended: break
            
        default: break
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
    
    func addSplashScreenToHierarchy () {
        screenShotView = presentingViewController()?.view.snapshotViewAfterScreenUpdates(true)
        screenShotView?.frame = contentView.frame
        screenShotView?.alpha = 0
        currentViewController.view.insertSubview(screenShotView!, belowSubview: contentView)
    }
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


