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
    
    optional func slideInteractiveTransitionPresentingView(controller: SlideInteractiveTransition) -> UIView?
}

class SlideInteractiveTransition: NSObject, UIGestureRecognizerDelegate {

    weak var delegate: SlideInteractiveTransitionDelegate?
    
    private weak var screenShotView: UIView?
    private weak var contentView: UIView!
    private weak var imageView: UIImageView?
    private weak var originImageView: UIImageView?
    lazy var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SlideInteractiveTransition.handlePanGesture(_:)))
    
    required init (contentView: UIView, imageView: UIImageView? = nil) {
        self.contentView = contentView
        originImageView = imageView
        super.init()
        panGestureRecognizer.delegate = self
        contentView.addGestureRecognizer(panGestureRecognizer)
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer) {
        guard let superview = contentView.superview else { return }
        let translation = gesture.translationInView(superview)
        let animate = UIApplication.sharedApplication().statusBarOrientation.isPortrait
        let presentingView = animate ? self.presentingView() : nil
        let cell = presentingView as? CandyCell
        cell?.gradientView.alpha = 0.0
        let percentCompleted = abs(translation.y/superview.height)
        switch gesture.state {
        case .Began:
            if let imageView = originImageView where animate == true && presentingView != nil {
                let _imageView = UIImageView(frame: imageView.frame)
                _imageView.image = imageView.image
                _imageView.contentMode = .ScaleAspectFit
                _imageView.center = superview.center
                self.imageView = _imageView
                superview.addSubview(_imageView)
                contentView.hidden = true
            }
            addScreenShotView(animate)
            delegate?.slideInteractiveTransition?(self, hideViews: true)
        case .Changed:
            if presentingView != nil  {
                imageView?.transform = CGAffineTransformMakeTranslation(translation.x, translation.y)
           
            } else {
                contentView.transform = CGAffineTransformMakeTranslation(0, translation.y)
            }
            screenShotView?.alpha = percentCompleted
        case .Ended, .Cancelled:
            if  (percentCompleted > 0.25 || abs(gesture.velocityInView(superview).y) > 1000) {
                let endPoint = superview.height
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.screenShotView?.alpha = 1
                    if let presentingView = presentingView {
                        guard let imageView = self.imageView else { return }
                        imageView.clipsToBounds = true
                        imageView.contentMode = .ScaleAspectFill
                        self.imageView?.frame = presentingView.convertRect(presentingView.bounds, toCoordinateSpace:self.snapshotView() ?? superview)
                    } else {
                        self.contentView.transform = CGAffineTransformMakeTranslation(0, translation.y <= 0 ? -endPoint : endPoint)
                    }
                    }, completion: { (finished) -> Void in
                        presentingView?.alpha = 1
                        self.imageView?.removeFromSuperview()
                        self.delegate?.slideInteractiveTransitionDidFinish?(self)
                        UIView.animateWithDuration(0.5, animations: { cell?.gradientView.alpha = 1.0 })
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    if presentingView != nil {
                        self.imageView?.frame = self.contentView.frame
                    } else {
                        self.contentView.transform = CGAffineTransformIdentity
                    }
                    }, completion: { _ in
                        presentingView?.alpha = 1
                        self.contentView.hidden = false
                        self.screenShotView?.removeFromSuperview()
                        self.imageView?.removeFromSuperview()
                        self.delegate?.slideInteractiveTransition?(self, hideViews: false)
                })
            }
        default:break
        }
    }
    
    private func snapshotView() -> UIView? {
        return delegate?.slideInteractiveTransitionSnapshotView?(self)
    }
    
    private func presentingView() -> UIView? {
        return self.delegate?.slideInteractiveTransitionPresentingView?(self)
    }
    
    func addScreenShotView(isPortrait: Bool) {
        if let screenShotView = snapshotView()?.snapshotViewAfterScreenUpdates(true) {
            screenShotView.alpha = 0
            if isPortrait != true {
                switch DeviceManager.defaultManager.orientation {
                case .LandscapeLeft:
                    screenShotView.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2));
                    break
                case .LandscapeRight:
                    screenShotView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
                    break
                default: break
                }
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