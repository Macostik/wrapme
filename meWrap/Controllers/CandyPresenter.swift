//
//  CandyPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

final class CandyPresenter: UIView {
    
    static func present(cell: CandyCell, history: History? = nil, dismissingView: Candy -> UIView?) -> Void {
        guard let candy = cell.entry else { return }
        guard let controller = candy.createViewController() as? HistoryViewController else { return }
        controller.history = history?.historyCandies
        controller.dismissingView = dismissingView
        controller.modalPresentationStyle = .OverCurrentContext
        let nc = UINavigationController.main
        nc.pushViewController(controller, animated: false)
        if candy.valid && cell.imageView.image != nil {
            let previousView = nc.viewControllers[nc.viewControllers.count - 2].view
            nc.view.insertSubview(previousView, atIndex: 0)
            controller.dismissingView = dismissingView
            controller.view.hidden = true
            controller.setBarsHidden(true, animated: false)
            CandyPresenter.present(candy, fromView: cell, completionHandler: { (_) -> Void in
                controller.view.hidden = false
                controller.setBarsHidden(false, animated: true)
                previousView.removeFromSuperview()
            })
        }
        controller.dismissingView = dismissingView
    }
    
    
    private var imageView = specify(UIImageView()) {
        $0.contentMode = .ScaleAspectFill
        $0.clipsToBounds = true
    }
    
    static func present(candy: Candy, fromView: UIView, completionHandler: () -> ()) {
        guard let url = candy.asset?.large, let image = InMemoryImageCache.instance[url] ?? ImageCache.defaultCache.imageWithURL(url) else {
            completionHandler()
            return
        }
        let presenter = CandyPresenter()
        let superview = presenter.addToSuperview()
        presenter.imageView.image = image
        StreamView.lock()
        presenter.imageView.frame = superview.convertRect(fromView.bounds, fromCoordinateSpace:fromView)
        fromView.hidden = true
        presenter.backgroundColor = UIColor(white: 0, alpha: 0)
        UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
            presenter.imageView.frame = presenter.size.fit(image.size).rectCenteredInSize(presenter.size)
            presenter.backgroundColor = UIColor(white: 0, alpha: 1)
            }, completion: { (_) -> Void in
                completionHandler()
                fromView.hidden = false
                presenter.removeFromSuperview()
                StreamView.unlock()
        })
    }
    
    static func dismiss(candy: Candy, dismissingView: (Candy -> UIView?)?) {
        guard let view = dismissingView?(candy) else { return }
        guard let url = candy.asset?.large else { return }
        guard let image = InMemoryImageCache.instance[url] ?? ImageCache.defaultCache.imageWithURL(url) else { return }
        let presenter = CandyPresenter()
        let superview = presenter.addToSuperview()
        presenter.imageView.image = image
        presenter.imageView.frame = presenter.size.fit(image.size).rectCenteredInSize(presenter.size)
        StreamView.lock()
        view.hidden = true
        presenter.backgroundColor = UIColor(white: 0, alpha: 1)
        UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
            presenter.backgroundColor = UIColor(white: 0, alpha: 0)
            presenter.imageView.frame = superview.convertRect(view.bounds, fromCoordinateSpace:view)
            }, completion: { (_) -> Void in
                view.hidden = false
                presenter.removeFromSuperview()
                StreamView.unlock()
        })
    }
    
    private func addToSuperview() -> UIView {
        let superview = UINavigationController.main.view
        frame = superview.frame
        addSubview(imageView)
        superview.addSubview(self)
        return superview
    }
}
