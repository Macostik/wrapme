//
//  FlowerMenu.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AudioToolbox

class FlowerMenuAction: UIButton {
    
    var block: (AnyObject? -> Void)?
    
    convenience init(action: String, block: AnyObject? -> Void) {
        self.init(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        self.block = block
        clipsToBounds = false
        setBackgroundImage(UIImage(named: "bg_menu_btn"), forState: .Normal)
        titleLabel?.font = UIFont(name: "icons", size: 21)
        setTitleColor(UIColor.whiteColor(), forState: .Normal)
        setTitleColor(Color.grayLight, forState: .Highlighted)
        layer.cornerRadius = bounds.width/2
        setTitle(action, forState: .Normal)
    }
}

private class FlowerMenuEntry: NSObject {
    weak var view: UIView?
    var constructor: (FlowerMenu -> Void)?
    init (view: UIView, constructor: (FlowerMenu -> Void)) {
        self.view = view
        self.constructor = constructor
    }
}

class FlowerMenu: UIView {
    
    private static var _sharedMenu = FlowerMenu()
    class func sharedMenu() -> FlowerMenu {
        return _sharedMenu
    }
    
    private var entries = Set<FlowerMenuEntry>()
    
    private var actions = [FlowerMenuAction]()
    
    private weak var currentView: UIView?
    
    private var centerPoint = CGPointZero
    
    weak var entry: AnyObject?
    
    var vibrate = true
    
    init() {
        super.init(frame: UIScreen.mainScreen().bounds)
        backgroundColor = UIColor.clearColor()
        alpha = 0.0
        setFullFlexible()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func entryForView(view: UIView) -> FlowerMenuEntry? {
        
        for entry in entries where entry.view == view {
            return entry
        }
        return nil
    }
    
    func registerView(view: UIView, constructor: (FlowerMenu -> Void)) {
        if let entry = entryForView(view) {
            entry.constructor = constructor
        } else {
            let entry = FlowerMenuEntry(view: view, constructor: constructor)
            entries.insert(entry)
            view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "present:"))
            while let index = entries.indexOf({ $0.view == nil }) {
                entries.removeAtIndex(index)
            }
        }
    }
    
    func show() {
        guard let view = currentView, let superview = view.window else {
            return
        }
        frame = superview.bounds
        superview.addSubview(self)
        setNeedsDisplay()
        alpha = 0
        DeviceManager.defaultManager.removeReceiver(self)
        
        UIView.animateWithDuration(0.12, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
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
        guard superview != nil else {
            return
        }
        DeviceManager.defaultManager.addReceiver(self)
        entry = nil
        UIView.animateWithDuration(0.12, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
            self.alpha = 0
            self.animateHiding()
            }, completion: completeHiding)
    }
    
    func animateHiding() {
        for action in actions {
            action.center = centerPoint
        }
    }
    
    func completeHiding(flag: Bool) {
        for action in actions {
            action.removeFromSuperview()
        }
        actions.removeAll()
        removeFromSuperview()
    }
    
    func addAction(action: String, block: AnyObject? -> Void) {
        let action = FlowerMenuAction(action: action, block: block)
        actions.append(action)
        addSubview(action)
        action.addTarget(self, action: "selectedAction:", forControlEvents: .TouchUpInside)
        action.center = centerPoint;
    }
    
    func present(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            if let view = sender.view {
                showInView(view, point:sender.locationInView(view))
            }
        }
    }
    
    func showInView(view: UIView, point: CGPoint) {
        guard let superview = view.window else {
            return
        }
        
        centerPoint = view.convertPoint(point, toView: superview)
        
        let rect = superview.convertRect(view.bounds, fromView: view)
        guard rect.contains(centerPoint) else {
            return
        }
        
        currentView = view
        for action in actions {
            action.removeFromSuperview()
        }
        actions.removeAll()
        
        guard let entry = entryForView(view) else {
            return
        }
        
        self.entry = nil
        
        vibrate = true
        
        guard let constructor = entry.constructor else {
            return
        }
        
        constructor(self)
        
        guard !actions.isEmpty else {
            return
        }

        if vibrate {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        
        show()
    }
    
    func selectedAction(sender: FlowerMenuAction) {
        if let block = sender.block, let entry = self.entry {
            block(entry)
        }
        hide()
    }
    
    override func drawRect(rect: CGRect) {
        if let view = currentView {
            let ctx = UIGraphicsGetCurrentContext()
            
            let color = UIColor(white: 0, alpha: 0.6)
            
            CGContextSetFillColorWithColor(ctx, color.CGColor)
            CGContextFillRect (ctx, rect)
            
            let frame = convertRect(view.bounds, fromView:view)
            
            CGContextSetShadowWithColor (ctx, CGSizeZero, 15.0, color.CGColor)
            CGContextClearRect(ctx, frame)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        hide()
    }
    
}

extension FlowerMenu: DeviceManagerNotifying {
    func manager(manager: DeviceManager, didChangeOrientation orientation: UIDeviceOrientation) {
        hide()
    }
}

extension FlowerMenu {
    func addDeleteAction(block: AnyObject? -> Void) {
        addAction("n", block:block)
    }
    
    func addLeaveAction(block: AnyObject? -> Void) {
        addAction("O", block:block)
    }
    
    func addReportAction(block: AnyObject? -> Void) {
        addAction("s", block:block)
    }
    
    func addDownloadAction(block: AnyObject? -> Void) {
        addAction("o", block:block)
    }
    
    func addCopyAction(block: AnyObject? -> Void) {
        addAction("Q", block:block)
    }
    
    func addEditPhotoAction(block: AnyObject? -> Void) {
        addAction("R", block:block)
    }
    
    func addDrawPhotoAction(block: AnyObject? -> Void) {
        addAction("8", block:block)
    }
}