//
//  HintView.swift
//  meWrap
//
//  Created by Yura Granchenko on 28/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class HintView: UIView {
    typealias Drawing = (ctx: CGContextRef, rect: CGRect) -> Void
    
    var drawing: Drawing?
    
    final class func showHintViewFromNibName(nibName: String, inView view: UIView = UIWindow.mainWindow.rootViewController?.view ?? UIWindow.mainWindow, drawing: Drawing? = nil) -> Bool {
        if let shownHints = NSUserDefaults.sharedUserDefaults?.shownHints {
            if shownHints.objectForKey(nibName) == nil {
                shownHints.setObject(true, forKey: nibName)
                NSUserDefaults.sharedUserDefaults?.shownHints = shownHints
                guard let hintView: HintView = loadFromNib(nibName) else { return false }
                hintView.drawing = drawing
                hintView.frame = view.frame
                view.addSubview(hintView)
                hintView.setFullFlexible()
                
                hintView.alpha = 0.0
                UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .CurveEaseIn , animations: {
                    hintView.alpha = 1.0
                    }, completion: nil)
                
                return true
            }
        }
        
        return false
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
            drawing?(ctx: ctx, rect: rect)
    }
}

extension HintView {
    final class func showHomeSwipeTransitionHintView() -> Bool {
        return showHintViewFromNibName("WLHomeSwipeTransitionView")
    }
}