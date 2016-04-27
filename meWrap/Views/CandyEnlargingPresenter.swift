//
//  CandyEnlargingPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class CandyEnlargingPresenter: UIView {
    
    private var candy: Candy?
    
    class func handleCandySelection(item: StreamItem?, entry: AnyObject?,  historyItem: HistoryItem? = nil, dismissingView: Candy -> UIView?) -> Void {
        guard let cell = item?.view as? CandyCell else { return }
        guard let candy = entry as? Candy else { return }
        guard let historyViewController = candy.viewController() as? HistoryViewController else { return }
        historyViewController.history = historyItem?.history
        historyViewController.dismissingView = dismissingView
        if candy.valid && cell.imageView.image != nil {
            let presenter = CandyEnlargingPresenter()
            presenter.candy = candy
            presenter.dismissingView = dismissingView
            historyViewController.presenter = presenter
            presenter.present(candy, fromView: cell, completionHandler: { (_) -> Void in
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
    
    func present(candy: Candy, fromView: UIView, completionHandler: (CandyEnlargingPresenter -> Void)) {
        guard let url = candy.asset?.large, let image = InMemoryImageCache.instance[url] ?? ImageCache.defaultCache.imageWithURL(url) else {
            completionHandler(self)
            return
        }
        if let superview = addToSuperview() {
            imageView.image = image
            StreamView.lock()
            imageView.frame = superview.convertRect(fromView.bounds, fromCoordinateSpace:fromView)
            fromView.hidden = true
            backgroundColor = UIColor(white: 0, alpha: 0)
            UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
                self.imageView.frame = self.size.fit(image.size).rectCenteredInSize(self.size)
                self.backgroundColor = UIColor(white: 0, alpha: 1)
                }, completion: { (_) -> Void in
                    completionHandler(self)
                    fromView.hidden = false
                    self.removeFromSuperview()
                    StreamView.unlock()
            })
        } else {
            completionHandler(self)
        }
    }
    
    func dismiss(candy: Candy) {
        guard let view = self.dismissingView?(candy) else { return }
        guard let url = candy.asset?.large else { return }
        guard let image = InMemoryImageCache.instance[url] ?? ImageCache.defaultCache.imageWithURL(url) else { return }
        if let superview = addToSuperview() {
            imageView.image = image
            imageView.frame = self.size.fit(image.size).rectCenteredInSize(self.size)
            StreamView.lock()
            view.hidden = true
            backgroundColor = UIColor(white: 0, alpha: 1)
            UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
                self.backgroundColor = UIColor(white: 0, alpha: 0)
                self.imageView.frame = superview.convertRect(view.bounds, fromCoordinateSpace:view)
                }, completion: { (_) -> Void in
                    view.hidden = false
                    self.removeFromSuperview()
                    StreamView.unlock()
            })
        }
    }
    
    private func addToSuperview() -> UIView? {
        let superview = UINavigationController.main.view
        frame = superview.frame
        addSubview(imageView)
        superview.addSubview(self)
        return superview
    }
}
