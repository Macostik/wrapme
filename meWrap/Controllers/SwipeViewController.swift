//
//  SwipeViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/3/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

enum SwipeDirection {
    case Forward, Reverse
}

private enum SwipePosition {
    case Center, Left, Right
}

class SwipeViewController: BaseViewController {
    
    deinit {
        scrollView?.delegate = nil
    }
    
    private weak var _viewController: UIViewController?
    weak var viewController: UIViewController? {
        get { return _viewController }
        set {
            if newValue != _viewController {
                if _viewController != _secondViewController {
                    removeViewController(_viewController)
                }
                _viewController = newValue
                addViewController(newValue)
                didChangeViewController(newValue)
            }
        }
    }
    
    private weak var _secondViewController: UIViewController?
    private weak var secondViewController: UIViewController? {
        get { return _secondViewController }
        set {
            if newValue != _secondViewController {
                if _secondViewController != _viewController {
                    removeViewController(_secondViewController)
                }
                _secondViewController = newValue
                addViewController(newValue)
            }
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var scrollWidth: CGFloat {
        return scrollView.width
    }
    
    private var _position: SwipePosition = .Center
    private var position: SwipePosition {
        get { return _position }
        set {
            if newValue != _position {
                _position = newValue
                if newValue == .Left {
                    layoutNextViewController(.Reverse)
                } else if (position == .Right) {
                    layoutNextViewController(.Forward)
                }
            }
        }
    }
    
    private func layoutNextViewController(direction: SwipeDirection) {
        if let viewController = viewControllerNextTo(viewController, direction: direction) {
            secondViewController = viewController
            layoutViewControllers(direction == .Reverse ? .Forward : .Reverse, animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.width = scrollView.width
        scrollView.contentSize = scrollView.size
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        scrollView.panGestureRecognizer.addTarget(self, action: "panning:")
    }
    
    func panning(sender: UIPanGestureRecognizer) {
        
        if (sender.state == .Began) {
            _position = .Center
        } else if (sender.state == .Changed) {
            if let viewController = viewController {
                
                let offset = scrollView.contentOffset.x - viewController.view.x
                if offset < 0 {
                    position = .Left
                } else if offset > 0 {
                    position = .Right
                } else {
                    position = .Center
                }
                swapViewControllersIfNeededWithContentOffset(scrollView.contentOffset)
            }
        }
    }
    
    private func addViewController(viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        addChildViewController(viewController)
        if viewController.view.superview != scrollView {
            viewController.view.frame = scrollView.bounds
            scrollView.addSubview(viewController.view)
        }
    }
    
    private func removeViewController(viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }
    
    func viewControllerNextTo(viewController: UIViewController?, direction: SwipeDirection) -> UIViewController? {
        return nil
    }
    
    func didChangeViewController(viewController: UIViewController?) { }
    
    private func sendDidChangeOffsetForViewController(viewController: UIViewController?) {
        if let viewController = viewController {
            let width = visibleWidthOfViewController(viewController)
            didChangeOffsetForViewController(viewController, offset:width / scrollWidth)
        }
    }
    
    func didChangeOffsetForViewController(viewController: UIViewController, offset: CGFloat) {
        viewController.view.alpha = offset
    }
    
    private func layoutViewControllers(direction: SwipeDirection, animated: Bool) {
        scrollView.contentSize = CGSizeMake(scrollWidth * 2, scrollView.height)
        let secondX: CGFloat = direction == .Forward ? 0 : scrollWidth
        let x: CGFloat = direction == .Forward ? scrollWidth : 0
        _secondViewController?.view.frame.origin.x = secondX
        _viewController?.view.frame.origin.x = x
        if animated {
            scrollView.contentOffset.x = secondX
            scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
        } else {
            scrollView.contentOffset.x = x
        }
    }
    
    func setViewController(viewController: UIViewController?, direction: SwipeDirection, animated: Bool) {
        if let viewController = viewController where animated {
            secondViewController = self.viewController
            self.viewController = viewController
            layoutViewControllers(direction, animated: true)
            Dispatch.mainQueue.after(0.5) {
                self.scrollViewDidEndDecelerating(self.scrollView)
            }
        } else {
            viewController?.view.frame.origin.x = 0
            self.viewController = viewController
            scrollViewDidEndDecelerating(scrollView)
            sendDidChangeOffsetForViewController(viewController)
        }
    }
    
    private func visibleWidthOfViewController(viewController: UIViewController) -> CGFloat {
        return scrollView.visibleRectOfRect(viewController.view.frame).width
    }
    
    private func visibleWidthOfViewController(viewController: UIViewController, offset: CGPoint) -> CGFloat {
        return scrollView.visibleRectOfRect(viewController.view.frame, offset: offset).size.width
    }
    
    private func swapViewControllersIfNeededWithContentOffset(contentOffset: CGPoint) {
        if let secondViewController = secondViewController {
            let width2 = visibleWidthOfViewController(secondViewController, offset: contentOffset)
            if width2 != 0 {
                let width1 = viewController != nil ? visibleWidthOfViewController(viewController!, offset: contentOffset) : 0
                let currentViewController = width1 > width2 ? self.viewController : self.secondViewController
                if self.viewController != currentViewController {
                    _secondViewController = viewController
                    _viewController = currentViewController
                    if _position == .Right {
                        _position = .Left
                    } else if _position == .Left {
                        _position = .Right
                    }
                    didChangeViewController(_viewController)
                }
            }
        }
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        viewController?.view.frame.size = scrollView.size
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        viewController?.view.frame.size = scrollView.size
    }
}

extension SwipeViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        sendDidChangeOffsetForViewController(viewController)
        sendDidChangeOffsetForViewController(secondViewController)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
       viewController?.view.x = 0
       secondViewController = nil
       scrollView.contentSize = scrollView.size
       scrollView.contentOffset = CGPointZero
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        swapViewControllersIfNeededWithContentOffset(targetContentOffset.memory)
    }
}
