//
//  StoryboardTransition.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class StoryboardTransition: NSObject {
    
    @IBOutlet weak var sourceViewController: UIViewController?
    
    private var destinationViewController: UIViewController? {
        if let controller = getDestinationViewController() {
            if let sourceValue = sourceValue {
                controller.setValue(sourceViewController?.valueForKeyPath(sourceValue), forKeyPath: destinationValue ?? sourceValue)
            }
            if sourceIsDelegate && controller.respondsToSelector(#selector(NSPort.setDelegate(_:))) {
                controller.performSelector(#selector(NSPort.setDelegate(_:)), withObject: sourceViewController)
            }
            return controller
        } else {
            return nil
        }
    }
    
    private func getDestinationViewController() -> UIViewController? {
        if let destinationID = destinationID {
            if let name = storyboard {
                return UIStoryboard(name: name, bundle: nil)[destinationID]
            } else {
                return sourceViewController?.storyboard?[destinationID]
            }
        } else if let name = storyboard {
            return UIStoryboard(name: name, bundle: nil).instantiateInitialViewController()
        } else {
            return nil
        }
    }
    
    @IBInspectable var destinationID: String?
    
    @IBInspectable var storyboard: String?
    
    @IBInspectable var sourceValue: String?
    
    @IBInspectable var destinationValue: String?
    
    @IBInspectable var sourceIsDelegate: Bool = false
    
    @IBInspectable var animated: Bool = false
    
    @IBAction func push(sender: AnyObject) {
        if let source = sourceViewController, let destination = destinationViewController {
            source.navigationController?.pushViewController(destination, animated: animated)
        }
    }
    
    @IBAction func pop(sender: AnyObject) {
        sourceViewController?.navigationController?.popViewControllerAnimated(animated)
    }
    
    @IBAction func present(sender: AnyObject) {
        if let source = sourceViewController, let destination = destinationViewController {
            source.presentViewController(destination, animated: animated, completion: nil)
        }
    }
}
