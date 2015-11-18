//
//  CandyInteractionController.swift
//  meWrap
//
//  Created by Yura Granchenko on 18/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class CandyInteractionController: NSObject {
    
    var contentView: UIView?
    var currentViewController: UIViewController?
    var screenShotView: UIView?
    var isMoveUp: Bool = false
    
    override init() {
        super.init()
    }
    
    var viewController: WLHistoryViewController? {
        didSet {
            if let viewController = viewController {
                if  let contentView = viewController.contentView {
                    let gesture = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
                    contentView.addGestureRecognizer(gesture)
                    self.contentView = contentView
                    self.currentViewController = viewController
                }
            }
        }
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translationPoint = gesture.translationInView(contentView)
        let velocity = gesture.velocityInView(contentView)
        switch gesture.state {
        case .Began:
            isMoveUp = velocity.y < 0
            self.addSplashScreenToHierarchy()
        case .Changed:
            UIView.performAnimated(true, animation: { () -> (Void) in
                self.contentView?.transform = CGAffineTransformMakeTranslation(0, translationPoint.y)
                self.screenShotView?.alpha = abs(translationPoint.y/(self.contentView?.height)!)
            })
            
        case .Cancelled, .Ended: break
            
        default: break
        }
    }
    
    func presentingViewController() -> UIViewController? {
        let viewControllers: NSArray = (currentViewController?.navigationController?.viewControllers)!
        let ownerIndex = viewControllers.indexOfObject(currentViewController!)
        let presentingViewController = viewControllers.objectAtIndex(ownerIndex) as! UIViewController
        return presentingViewController
    }
    
    func addSplashScreenToHierarchy () {
        screenShotView = presentingViewController()?.view.snapshotViewAfterScreenUpdates(true)
        screenShotView?.frame = (contentView?.frame)!
        screenShotView?.alpha = 0
        currentViewController?.view.insertSubview(screenShotView!, belowSubview: contentView!)
    }
}
