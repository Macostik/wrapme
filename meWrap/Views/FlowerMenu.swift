//
//  FlowerMenu.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AudioToolbox
import SnapKit

class FlowerMenuAction: Button {
    
    var block: (Void -> Void)?
    
    convenience init(action: String, color: UIColor, block: Void -> Void) {
        self.init(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        self.block = block
        backgroundColor = color
        normalColor = color
        highlightedColor = color.darkerColor()
        cornerRadius = 19
        clipsToBounds = true
        titleLabel?.font = UIFont.icons(21)
        setTitleColor(UIColor.whiteColor(), forState: .Normal)
        setTitleColor(Color.grayLighter, forState: .Highlighted)
        layer.cornerRadius = bounds.width/2
        setTitle(action, forState: .Normal)
    }
}

protocol FlowerMenuConstructor {
    func constructFlowerMenu(menu: FlowerMenu)
}

class FlowerMenu: UIView {
    
    static var sharedMenu = FlowerMenu()
    
    private var actions = [FlowerMenuAction]()
    
    private weak var currentView: UIView?
    
    private var centerPoint = CGPointZero
    
    var vibrate = true
    
    func registerView<T: UIView where T: FlowerMenuConstructor>(view: T) {
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(FlowerMenu.present(_:))))
    }
    
    func show() {
        guard let superview = currentView?.window else { return }
        frame = superview.bounds
        backgroundColor = UIColor.clearColor()
        alpha = 0.0
        superview.addSubview(self)
        snp_makeConstraints(closure: { $0.edges.equalTo(superview) })
        setNeedsDisplay()
        alpha = 0
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.hide), name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)
        UIView.animateWithDuration(0.12, delay: 0, options: .CurveEaseIn, animations: {
            self.alpha = 1
        }, completion: nil)
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .CurveEaseIn, animations: animateShowing, completion: nil)
    }
    
    func animateShowing() {
        
        let count = CGFloat(actions.count)
        let range = CGFloat(M_PI_4) * count
        var delta = -CGFloat(M_PI_2)
        if centerPoint.x >= 2*width/3 {
            delta -= range
        } else if centerPoint.x >= width/3 {
            delta -= range/2
        }
        
        let radius: CGFloat = 60
        
        for (index, action) in actions.enumerate() {
            var angle: CGFloat = 0
            if count > 1 {
                angle = range*(CGFloat(index)/(count - 1)) + delta
            } else {
                angle = delta
            }
            action.center = CGPoint(x: centerPoint.x + radius*cos(angle), y: centerPoint.y + radius*sin(angle))
        }
    }
    
    func hide() {
        guard superview != nil else { return }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)
        UIView.animateWithDuration(0.12, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
            self.alpha = 0
            self.animateHiding()
            }, completion: completeHiding)
    }
    
    func animateHiding() {
        actions.all({ $0.center = centerPoint })
    }
    
    func completeHiding(flag: Bool) {
        actions.all({ $0.removeFromSuperview() })
        actions.removeAll()
        removeFromSuperview()
    }
    
    func addAction(action: String, color: UIColor, block: Void -> Void) {
        let action = FlowerMenuAction(action: action, color: color, block: block)
        actions.append(action)
        addSubview(action)
        action.addTarget(self, action: #selector(FlowerMenu.selectedAction(_:)), forControlEvents: .TouchUpInside)
        action.center = centerPoint
    }
    
    func present(sender: UILongPressGestureRecognizer) {
        if let view = sender.view where sender.state == .Began {
            showInView(view, point:sender.locationInView(view))
        }
    }
    
    func showInView(view: UIView, point: CGPoint) {
        guard let superview = view.window else { return }
        
        centerPoint = view.convertPoint(point, toView: superview)
        
        let rect = superview.convertRect(view.bounds, fromView: view)
        guard rect.contains(centerPoint) else { return }
        
        currentView = view
        actions.all({ $0.removeFromSuperview() })
        actions.removeAll()
        
        guard let constructor = view as? FlowerMenuConstructor else { return }
        
        vibrate = true
        
        constructor.constructFlowerMenu(self)
        
        guard !actions.isEmpty else { return }

        if vibrate {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        
        show()
    }
    
    func selectedAction(sender: FlowerMenuAction) {
        sender.block?()
        hide()
    }
    
    override func drawRect(rect: CGRect) {
        if let view = currentView {
            let ctx = UIGraphicsGetCurrentContext()
            let color = UIColor(white: 0, alpha: 0.6)
            CGContextSetFillColorWithColor(ctx, color.CGColor)
            CGContextFillRect (ctx, rect)
            CGContextSetShadowWithColor (ctx, CGSizeZero, 15.0, color.CGColor)
            CGContextClearRect(ctx, targetRect(view))
        }
    }
    
    private func targetRect(view: UIView) -> CGRect {
        var viewFrame = view.frame
        var superview: UIView? = view.superview
        while let _superview = superview {
            let visibleRect = _superview.layer.bounds.intersect(viewFrame)
            if let sv = _superview.superview {
                viewFrame = sv.convertRect(visibleRect, fromView:_superview)
                superview = _superview.superview
            } else {
                return viewFrame
            }
        }
        return convertRect(view.bounds, fromView:view)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        hide()
    }
}

extension FlowerMenu {
    
    func addDeleteAction(block: Void -> Void) {
        addAction("n", color: Color.redOption, block:block)
    }
    
    func addReportAction(block: Void -> Void) {
        addAction("s", color: Color.redOption, block:block)
    }
    
    func addDownloadAction(block: Void -> Void) {
        addAction("o", color: Color.greenOption, block:block)
    }
    
    func addCopyAction(block: Void -> Void) {
        addAction("Q", color: Color.orange, block:block)
    }
    
    func addEditPhotoAction(block: Void -> Void) {
        addAction("R", color: Color.blue, block:block)
    }
    
    func addDrawPhotoAction(block: Void -> Void) {
        addAction("8", color: Color.purple, block:block)
    }
    
    func addShareAction(block: Void -> Void) {
        addAction("h", color: UIColor.blackColor().colorWithAlphaComponent(0.8), block:block)
    }
}