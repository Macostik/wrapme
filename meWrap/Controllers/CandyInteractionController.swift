//
//  CandyInteractionController.swift
//  meWrap
//
//  Created by Yura Granchenko on 18/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol CandyInteractionControllerDelegate {
    
    optional func candyInteractionController(controller: CandyInteractionController, hideViews: Bool)
    
    optional func candyInteractionControllerDidFinish(controller: CandyInteractionController)
    
    optional func candyInteractionControllerSnapshotView(controller: CandyInteractionController) -> UIView?
}

class CandyInteractionController: NSObject, UIGestureRecognizerDelegate {

    weak var delegate: CandyInteractionControllerDelegate?
    
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
        let translation = gesture.translationInView(contentView).y
        let percentCompleted = abs(translation/contentView.height)
        switch gesture.state {
        case .Began:
            addScreenShotView()
            delegate?.candyInteractionController?(self, hideViews: true)
        case .Changed:
            contentView.transform = CGAffineTransformMakeTranslation(0, translation)
            screenShotView?.alpha = percentCompleted
        case .Ended, .Cancelled:
            if  (percentCompleted > 0.5 || abs(gesture.velocityInView(contentView).y) > 1000) {
                let endPoint = contentView.height
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.screenShotView?.alpha = 1
                    self.contentView.transform = CGAffineTransformMakeTranslation(0, translation <= 0 ? -endPoint : endPoint)
                    }, completion: { (finished) -> Void in
                        self.delegate?.candyInteractionControllerDidFinish?(self)
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { [weak self] () -> Void in
                     self!.contentView.transform = CGAffineTransformIdentity
                    }, completion: { (finished) -> Void in
                        self.screenShotView?.removeFromSuperview()
                        self.delegate?.candyInteractionController?(self, hideViews: false)
                })
            }
        default:break
        }
    }
    
    private func snapshotView() -> UIView? {
        return delegate?.candyInteractionControllerSnapshotView?(self)
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