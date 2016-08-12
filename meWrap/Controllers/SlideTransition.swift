//
//  SlideTransition.swift
//  meWrap
//
//  Created by Yura Granchenko on 18/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class SlideTransition: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    
    var didStart: (() -> ())?
    var didCancel: (() -> ())?
    var didFinish: (() -> ())?
    
    var contentView: (() -> UIView?)?
    
    required init() {
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(self.panned(_:)))
        delegate = self
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
            didStart?()
        case .Changed:
            contentView.transform = CGAffineTransformMakeTranslation(0, translation.y)
        case .Ended, .Cancelled:
            if  (percentCompleted > 0.25 || abs(gesture.velocityInView(superview).y) > 1000) {
                let endPoint = superview.height
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    contentView.transform = CGAffineTransformMakeTranslation(0, translation.y <= 0 ? -endPoint : endPoint)
                    }, completion: { (finished) -> Void in
                        self.didFinish?()
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    contentView.transform = CGAffineTransformIdentity
                    }, completion: { _ in
                        self.didCancel?()
                })
            }
        default:break
        }
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if self == gestureRecognizer {
            let velocity = velocityInView(gestureRecognizer.view)
            return abs(velocity.x) < abs(velocity.y)
        } else {
            return true
        }
    }
}

final class ShrinkTransition: SlideTransition {
    
    private weak var dismissingView: UIView?
    
    private weak var imageView: UIImageView?
    
    private weak var controller: HistoryViewController?
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let controller = controller?.viewController where controller.imageView.image != nil {
            if let controller = controller as? PhotoCandyViewController where controller.scrollView.zoomScale != 1 {
                return false
            } else {
                return super.gestureRecognizerShouldBegin(gestureRecognizer)
            }
        } else {
            return false
        }
    }
    
    override func panned(gesture: UIPanGestureRecognizer) {
        
        if gesture.state == .Began {
            dismissingView = controller?.candyDismissingView()?()
        }
        
        if let dismissingView = dismissingView, let image = controller?.viewController?.imageView.image {
            shrink(gesture, image: image, dismissingView: dismissingView)
        } else {
            guard let contentView = controller?.viewController?.view ?? gesture.view else { return }
            guard let superview = contentView.superview else { return }
            let translation = gesture.translationInView(superview)
            let percentCompleted = abs(translation.y/superview.height)
            switch gesture.state {
            case .Began:
                didStart?()
            case .Changed:
                if let previousView = UINavigationController.main.viewControllers.suffix(2).first?.view {
                    UINavigationController.main.view.insertSubview(previousView, atIndex: 0)
                }
                controller?.setBarsHidden(true, animated: true, additionalAnimation: {
                    self.controller?.commentButton.alpha = 0
                })
                contentView.transform = CGAffineTransformMakeTranslation(0, translation.y)
                controller?.view?.backgroundColor = UIColor(white: 0, alpha: 1 - percentCompleted)
            case .Ended, .Cancelled:
                if  (percentCompleted > 0.25 || abs(gesture.velocityInView(superview).y) > 1000) {
                    let endPoint = superview.height
                    UIView.animateWithDuration(0.25, animations: { () -> Void in
                        self.controller?.view?.backgroundColor = UIColor(white: 0, alpha: 0)
                        contentView.transform = CGAffineTransformMakeTranslation(0, translation.y <= 0 ? -endPoint : endPoint)
                        }, completion: { (finished) -> Void in
                            UINavigationController.main.viewControllers.suffix(2).first?.view.removeFromSuperview()
                            UINavigationController.main.popViewControllerAnimated(false)
                    })
                } else {
                    UIView.animateWithDuration(0.25, animations: { () -> Void in
                        self.controller?.view?.backgroundColor = UIColor(white: 0, alpha: 1)
                        contentView.transform = CGAffineTransformIdentity
                        }, completion: { _ in
                            UINavigationController.main.viewControllers.suffix(2).first?.view.removeFromSuperview()
                            self.controller?.setBarsHidden(false, animated: true, additionalAnimation: {
                                self.controller?.commentButton.alpha = 1
                            })
                    })
                }
            default:break
            }
        }
    }
    
    func shrink(gesture: UIPanGestureRecognizer, image: UIImage, dismissingView: UIView) {
        guard let contentView = controller?.viewController?.view ?? gesture.view else { return }
        guard let superview = contentView.superview else { return }
        let translation = gesture.translationInView(superview)
        let percentCompleted = abs(translation.y/superview.height)
        let cell: CandyCell? = dismissingView as? CandyCell
        cell?.gradientView.alpha = 0
        switch gesture.state {
        case .Began:
            dismissingView.alpha = 0
            let imageView = UIImageView(frame: superview.size.fit(image.size).rectCenteredInSize(superview.size))
            imageView.image = image
            imageView.contentMode = .ScaleAspectFill
            imageView.clipsToBounds = true
            self.imageView = imageView
            superview.addSubview(imageView)
            contentView.hidden = true
            if let previousView = UINavigationController.main.viewControllers.suffix(2).first?.view {
                UINavigationController.main.view.insertSubview(previousView, atIndex: 0)
            }
            controller?.setBarsHidden(true, animated: true, additionalAnimation: {
                self.controller?.commentButton.alpha = 0
            })
        case .Changed:
            imageView?.transform = CGAffineTransformMakeTranslation(translation.x, translation.y)
            controller?.view?.backgroundColor = UIColor(white: 0, alpha: 1 - percentCompleted)
        case .Ended, .Cancelled:
            if (percentCompleted > 0.25 || abs(gesture.velocityInView(superview).y) > 1000) {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.controller?.view?.backgroundColor = UIColor(white: 0, alpha: 0)
                    self.imageView?.frame = dismissingView.convertRect(dismissingView.bounds, toCoordinateSpace:self.controller?.view ?? superview)
                    }, completion: { (finished) -> Void in
                        dismissingView.alpha = 1
                        self.imageView?.removeFromSuperview()
                        UINavigationController.main.viewControllers.suffix(2).first?.view.removeFromSuperview()
                        UINavigationController.main.popViewControllerAnimated(false)
                        UIView.animateWithDuration(0.5, animations: { cell?.gradientView.alpha = 1.0 })
                })
            } else {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.imageView?.transform = CGAffineTransformIdentity
                    self.controller?.view?.backgroundColor = UIColor(white: 0, alpha: 1)
                    }, completion: { _ in
                        dismissingView.alpha = 1
                        contentView.hidden = false
                        self.imageView?.removeFromSuperview()
                        UINavigationController.main.viewControllers.suffix(2).first?.view.removeFromSuperview()
                        self.controller?.setBarsHidden(false, animated: true, additionalAnimation: {
                            self.controller?.commentButton.alpha = 1
                        })
                        UIView.animateWithDuration(0.5, animations: { cell?.gradientView.alpha = 1.0 })
                })
            }
        default:break
        }
    }
}

extension HistoryViewController {
    
    func candyDismissingView() -> (() -> UIView?)? {
        return { [weak self] _ in
            guard let candy = self?.candy else { return nil }
            return self?.dismissingView?(candy)
        }
    }
    
    func createShrinkTransition() -> ShrinkTransition {
        let transition = ShrinkTransition()
        transition.controller = self
        transition.requireGestureRecognizerToFail(swipeUpGesture)
        transition.requireGestureRecognizerToFail(swipeDownGesture)
        contentView.addGestureRecognizer(transition)
        return transition
    }
}