//
//  UIViewController+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIViewController {
    func addContainedViewController(controller: UIViewController, animated: Bool) {
        addContainedViewController(controller, toView:self.view, animated:animated)
    }
    
    func addContainedViewController(controller: UIViewController, toView view: UIView, animated: Bool) {
        addChildViewController(controller)
        view.addSubview(controller.view)
        controller.view.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        controller.didMoveToParentViewController(self)
    }
    
    func removeContainedViewController(controller: UIViewController, animated: Bool) {
        controller.removeFromContainerAnimated(animated)
    }
    
    func addToContainer(container: UIViewController, animated: Bool) {
        container.addContainedViewController(self, animated:animated)
    }
    
    func removeFromContainerAnimated(animated: Bool) {
        willMoveToParentViewController(nil)
        view.removeFromSuperview()
        removeFromParentViewController()
    }
    
    func modalPresentationOverContext(controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        controller.modalPresentationStyle = .OverCurrentContext
        controller.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        self.presentViewController(controller, animated: animated, completion: completion)
    }
    
    func recursivePresentedViewController() -> UIViewController {
        return presentedViewController?.recursivePresentedViewController() ?? self
    }
}

extension UIViewController {
    
    var isTopViewController: Bool {
        return navigationController?.topViewController == self
    }
    
    @IBAction func back(sender: UIButton) {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func backButton(color: UIColor) -> Button {
        return backButton(color, action: #selector(self.back(_:)))
    }
    
    func backButton(color: UIColor, action: Selector) -> Button {
        let backButton = Button(icon: "w", size: 24, textColor: color)
        backButton.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        backButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        backButton.setTitleColor(color.darkerColor(), forState: .Highlighted)
        backButton.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        return backButton
    }
}