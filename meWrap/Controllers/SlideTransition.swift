//
//  SlideTransition.swift
//  meWrap
//
//  Created by Yura Granchenko on 18/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class SlideTransition: NSObject, UIGestureRecognizerDelegate {
    
    var shouldStart: () -> Bool = { _ in return true }
    var didStart: (() -> ())?
    var didCancel: (() -> ())?
    var didFinish: (() -> ())?
    
    var contentView: (() -> UIView?)?
    var snapshotView: (() -> UIView?)?
    
    private weak var _snapshotView: UIView?
    
    let panGestureRecognizer = UIPanGestureRecognizer()
    
    required init(view: UIView) {
        super.init()
        panGestureRecognizer.addTarget(self, action: #selector(self.panned(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    func panned(gesture: UIPanGestureRecognizer) {
        slide(gesture)
    }
    
    func slide(gesture: UIPanGestureRecognizer) {
        guard let contentView = contentView?() ?? gesture.view else { return }
        guard let superview = contentView.superview else { return }
        let translation = gesture.translationInView(superview)
        let percentCompleted = abs(translation.y/superview.height)
        switch gesture.state {
        case .Began:
            addSnapshotView(contentView)
            didStart?()
        case .Changed:
            contentView.transform = CGAffineTransformMakeTranslation(0, translation.y)
            _snapshotView?.alpha = percentCompleted
        case .Ended, .Cancelled:
            if  (percentCompleted > 0.25 || abs(gesture.velocityInView(superview).y) > 1000) {
                let endPoint = superview.height
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self._snapshotView?.alpha = 1
                    contentView.transform = CGAffineTransformMakeTranslation(0, translation.y <= 0 ? -endPoint : endPoint)
                    }, completion: { (finished) -> Void in
                        self.didFinish?()
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    contentView.transform = CGAffineTransformIdentity
                    self._snapshotView?.alpha = 0
                    }, completion: { _ in
                        self._snapshotView?.removeFromSuperview()
                        self.didCancel?()
                })
            }
        default:break
        }
    }
    
    private func addSnapshotView(contentView: UIView) {
        if let snapshotView = snapshotView?()?.snapshotViewAfterScreenUpdates(true) {
            snapshotView.alpha = 0
            switch DeviceManager.defaultManager.orientation {
            case .LandscapeLeft:
                snapshotView.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2));
                break
            case .LandscapeRight:
                snapshotView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
                break
            default: break
            }
            snapshotView.frame = UIScreen.mainScreen().bounds
            contentView.superview?.insertSubview(snapshotView, belowSubview: contentView)
            self._snapshotView = snapshotView
        }
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if panGestureRecognizer == gestureRecognizer {
            let velocity = panGestureRecognizer.velocityInView(gestureRecognizer.view)
            return abs(velocity.x) < abs(velocity.y) && shouldStart()
        } else {
            return true
        }
    }
}

class ShrinkTransition: SlideTransition {
    
    var dismissingView: (() -> UIView?)?
    var image: (() -> UIImage?)?
    
    private weak var _dismissingView: UIView?
    
    private weak var imageView: UIImageView?
    
    override func panned(gesture: UIPanGestureRecognizer) {
        
        if gesture.state == .Began {
            _dismissingView = dismissingView?()
        }
        
        let orientationIsPortrait = UIApplication.sharedApplication().statusBarOrientation.isPortrait
        if let dismissingView = _dismissingView, let image = image?() where orientationIsPortrait {
            shrink(gesture, image: image, dismissingView: dismissingView)
        } else {
            slide(gesture)
        }
    }
    
    func shrink(gesture: UIPanGestureRecognizer, image: UIImage, dismissingView: UIView) {
        guard let contentView = contentView?() ?? gesture.view else { return }
        guard let superview = contentView.superview else { return }
        let translation = gesture.translationInView(superview)
        let percentCompleted = abs(translation.y/superview.height)
        let cell: CandyCell? = _dismissingView as? CandyCell
        cell?.gradientView.alpha = 0
        switch gesture.state {
        case .Began:
            _dismissingView?.alpha = 0
            let imageView = UIImageView(frame: superview.size.fit(image.size).rectCenteredInSize(superview.size))
            imageView.image = image
            imageView.contentMode = .ScaleAspectFill
            imageView.clipsToBounds = true
            self.imageView = imageView
            superview.addSubview(imageView)
            contentView.hidden = true
            addSnapshotView(contentView)
            didStart?()
        case .Changed:
            imageView?.transform = CGAffineTransformMakeTranslation(translation.x, translation.y)
            _snapshotView?.alpha = percentCompleted
        case .Ended, .Cancelled:
            if (percentCompleted > 0.25 || abs(gesture.velocityInView(superview).y) > 1000) {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self._snapshotView?.alpha = 1
                    self.imageView?.transform = CGAffineTransformIdentity
                    self.imageView?.frame = dismissingView.convertRect(dismissingView.bounds, toCoordinateSpace:superview)
                    }, completion: { (finished) -> Void in
                        self._dismissingView?.alpha = 1
                        self.imageView?.removeFromSuperview()
                        self.didFinish?()
                        UIView.animateWithDuration(0.5, animations: { cell?.gradientView.alpha = 1.0 })
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.imageView?.transform = CGAffineTransformIdentity
                    self._snapshotView?.alpha = 0
                    }, completion: { _ in
                        self._dismissingView?.alpha = 1
                        contentView.hidden = false
                        self._snapshotView?.removeFromSuperview()
                        self.imageView?.removeFromSuperview()
                        self.didCancel?()
                        UIView.animateWithDuration(0.5, animations: { cell?.gradientView.alpha = 1.0 })
                })
            }
        default:break
        }
    }
}