//
//  HintView.swift
//  meWrap
//
//  Created by Yura Granchenko on 28/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

final class HintView: UIView {
    
    class func show(nibName: String, inView view: UIView = UIWindow.mainWindow.rootViewController?.view ?? UIWindow.mainWindow) {
        var shownHints = NSUserDefaults.standardUserDefaults().shownHints
        if shownHints[nibName] == nil {
            shownHints[nibName] = true
            NSUserDefaults.standardUserDefaults().shownHints = shownHints
            guard let hintView: HintView = loadFromNib(nibName) else { return }
            hintView.frame = view.frame
            view.addSubview(hintView)
            hintView.setFullFlexible()
            hintView.alpha = 0.0
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .CurveEaseIn , animations: {
                hintView.alpha = 1.0
                }, completion: nil)
        }
    }
    
    @IBAction func hide(sender: AnyObject) {
        UIView.animateWithDuration(0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .CurveEaseIn, animations: { () -> Void in
                self.alpha = 0.0
            }) { _ in
                self.removeFromSuperview()
        }
    }
    
    override func drawRect(rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let colors = [UIColor.blackColor().CGColor, UIColor.blackColor().colorWithAlphaComponent(0.85).CGColor]
        let gradient = CGGradientCreateWithColors(nil, colors , nil)
        CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0.5, 0.0), CGPointMake(0.5, rect.width), .DrawsAfterEndLocation)
    }
}

extension HintView {
    class func showHomeSwipeTransitionHintView() {
        show("WLHomeSwipeTransitionView")
    }
}