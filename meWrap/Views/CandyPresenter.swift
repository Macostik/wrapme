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
        guard let historyViewController = candy.createViewController() as? HistoryViewController else { return }
        historyViewController.history = history
        historyViewController.dismissingView = dismissingView
        if candy.valid && cell.imageView.image != nil {
            historyViewController.dismissingView = dismissingView
            CandyPresenter.present(candy, fromView: cell, completionHandler: { (_) -> Void in
                UINavigationController.main.pushViewController(historyViewController, animated: false)
            })
        } else {
            UINavigationController.main.pushViewController(historyViewController, animated: false)
        }
        historyViewController.dismissingView = dismissingView
    }
    
    
    private var imageView = specify(UIImageView()) {
        $0.contentMode = .ScaleAspectFill
        $0.clipsToBounds = true
    }
    
    var dismissingView: (Candy -> UIView?)?
    
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
