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
        controller.view.frame = view.bounds;
        view.addSubview(controller.view)
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
}

extension UIViewController {
    
    func requestAuthorizationForPresentingEntry(entry: Entry, completion: WLBooleanBlock) {
        completion(true)
    }
    
    var isTopViewController: Bool {
        return navigationController?.topViewController == self
    }
    
    @IBAction func back(sender: UIButton) {
        navigationController?.popViewControllerAnimated(false)
    }
}