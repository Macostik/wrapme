//
//  CandyEnlargingPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class CandyEnlargingPresenter: UIView {
    
    class func handleCandySelection(item: StreamItem?, entry: AnyObject?, dismissingView: ((presenter: CandyEnlargingPresenter, candy: Candy) -> UIView?)) -> Void {
        handleCandySelection(item, entry: entry, historyItem: nil, dismissingView: dismissingView)
    }
    
    class func handleCandySelection(item: StreamItem?, entry: AnyObject?,  historyItem: HistoryItem?, dismissingView: ((presenter: CandyEnlargingPresenter, candy: Candy) -> UIView?)) -> Void {
        guard let cell = item?.view as? CandyCell, let candy = entry as? Candy else {
            return
        }
        if candy.valid && cell.imageView.image != nil {
            if let historyViewController = candy.viewController() as? WLHistoryViewController {
                historyViewController.historyItem = historyItem
                let presenter = CandyEnlargingPresenter()
                historyViewController.presenter = presenter
                let presented = presenter.present(candy, fromView: cell, completionHandler: { (_) -> Void in
                    UINavigationController.main()?.pushViewController(historyViewController, animated: false)
                })
                if presented {
                    presenter.dismissingView = dismissingView
                } else {
                    ChronologicalEntryPresenter.presentEntry(candy, animated: true)
                }
            }
        } else {
            ChronologicalEntryPresenter.presentEntry(candy, animated: true)
        }
    }
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    var dismissingView: ((presenter: CandyEnlargingPresenter, candy: Candy) -> UIView?)?
    
    func present(candy: Candy, fromView: UIView, completionHandler: (CandyEnlargingPresenter -> Void)?) -> Bool {
        guard let url = candy.asset?.large else { return false }
        guard let image = InMemoryImageCache.instance[url] ?? ImageCache.defaultCache.imageWithURL(url) else { return false }
        if let superview = addToSuperview() {
            imageView.image = image;
            StreamView.lock()
            imageView.frame = superview.convertRect(fromView.bounds, fromCoordinateSpace:fromView)
            fromView.hidden = true
            backgroundColor = UIColor(white: 0, alpha: 0)
            UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
                self.imageView.frame = CGRectThatFitsSize(self.size, image.size)
                self.backgroundColor = UIColor(white: 0, alpha: 1)
                }, completion: { (_) -> Void in
                    completionHandler?(self)
                    fromView.hidden = false
                    self.removeFromSuperview()
                    StreamView.unlock()
            })
            return true
        } else {
            return false
        }
    }
    
    func dismiss(candy: Candy) {
        guard let view = self.dismissingView?(presenter: self, candy: candy) else { return }
        guard let url = candy.asset?.large else { return }
        guard let image = InMemoryImageCache.instance[url] ?? ImageCache.defaultCache.imageWithURL(url) else { return }
        if let superview = addToSuperview() {
            imageView.image = image
            imageView.frame = CGRectThatFitsSize(self.size, image.size)
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
        if let superview = UIWindow.mainWindow.rootViewController?.view {
            frame = superview.frame
            addSubview(imageView)
            superview.addSubview(self)
            return superview
        } else {
            return nil
        }
    }
}
