//
//  EntryPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class EntryPresenter: NSObject {
    
    class func presentEntry(entry: Entry, animated: Bool) {
        if let navigationController = UINavigationController.main() {
            presentEntry(entry, inNavigationController: navigationController, animated:animated)
        }
    }
    
    class func presentEntry(entry: Entry, inNavigationController navigationController: UINavigationController, animated: Bool) {
        
    }
    
    class func presentEntryRequestingAuthorization(entry: Entry, animated: Bool) {
        if let navigationController = UINavigationController.main() {
            presentEntryRequestingAuthorization(entry, inNavigationController: navigationController, animated:animated)
        }
    }
    
    class func presentEntryRequestingAuthorization(entry: Entry, inNavigationController navigationController: UINavigationController, animated: Bool) {
        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.requestAuthorizationForPresentingEntry(entry, completion: { (flag) -> Void in
                if (flag) {
                    navigationController.dismissViewControllerAnimated(false, completion: { () -> Void in
                        self.presentEntry(entry, inNavigationController: navigationController, animated:animated)
                    })
                }
            })
        } else {
            self.presentEntry(entry, inNavigationController: navigationController, animated:animated)
        }
    }
}

extension UIViewController {
    func requestAuthorizationForPresentingEntry(entry: Entry, completion: BooleanBlock) {
        completion(true)
    }
}

extension Entry {
    func viewController() -> UIViewController? {
        return nil
    }
    
    func viewControllerWithNavigationController(navigationController: UINavigationController) -> UIViewController? {
        for viewController in navigationController.viewControllers {
            if isValidViewController(viewController) {
                return viewController
            }
        }
        return viewController()
    }
    
    func recursiveViewControllerWithNavigationController(navigationController: UINavigationController) -> UIViewController? {
        var _currentEntry: Entry? = self
        while let currentEntry = _currentEntry where currentEntry.valid {
            if let controller = currentEntry.viewControllerWithNavigationController(navigationController) {
                if currentEntry != self {
                    configureViewController(controller, fromContainer:currentEntry)
                }
                return controller
            } else {
                _currentEntry = currentEntry.container
            }
        }
        return nil
    }
    
    func isValidViewController(controller: UIViewController) -> Bool {
        return false
    }
    
    func configureViewController(controller: UIViewController, fromContainer container: Entry) {
        
    }
}

extension Candy {
    
    override func viewController() -> UIViewController? {
        return Storyboard.History.instantiate({ $0.candy = self })
    }
    
    override func isValidViewController(controller: UIViewController) -> Bool {
        return (controller as? HistoryViewController)?.candy == self
    }
}

extension Message {
    
    override func viewController() -> UIViewController? {
        let controller = wrap?.viewController() as? WrapViewController
        controller?.segment = .Chat
        return controller
    }
    
    override func viewControllerWithNavigationController(navigationController: UINavigationController) -> UIViewController? {
        let controller = super.viewControllerWithNavigationController(navigationController)
        if let controller = controller as? WrapViewController {
            controller.segment = .Chat
        }
        return controller
    }
    
    override func isValidViewController(controller: UIViewController) -> Bool {
        return (controller as? WrapViewController)?.wrap == wrap
    }
}

extension Wrap {
    
    override func viewController() -> UIViewController? {
        let controller = UIStoryboard.main["wrap"] as? WrapViewController
        controller?.wrap = self
        return controller
    }
    
    override func isValidViewController(controller: UIViewController) -> Bool {
        return (controller as? WrapViewController)?.wrap == self
    }
}

extension Comment {
    
    override func configureViewController(controller: UIViewController, fromContainer container: Entry) {
        if container == candy, let controller = controller as? HistoryViewController {
            performWhenLoaded(controller, block: { $0.showCommentView() })
        }
    }
}

class HierarchicalEntryPresenter: EntryPresenter {
    
    override class func presentEntry(entry: Entry, inNavigationController navigationController: UINavigationController, animated: Bool) {
        var viewControllers = self.viewControllersForEntry(entry, inNavigationController: navigationController)
        if let controller = navigationController.viewControllers.first {
            viewControllers.insert(controller, atIndex: 0)
        }
        navigationController.setViewControllers(viewControllers, animated:animated)
    }
    
    class func viewControllersForEntry(entry: Entry, inNavigationController navigationController: UINavigationController) -> [UIViewController] {
        var viewControllers = [UIViewController]()
        var _currentEntry: Entry? = entry
        while let currentEntry = _currentEntry where currentEntry.valid {
            if let controller = currentEntry.viewControllerWithNavigationController(navigationController) {
                viewControllers.append(controller)
                if currentEntry != entry {
                    entry.configureViewController(controller, fromContainer:currentEntry)
                }
            }
            _currentEntry = currentEntry.container;
        }
        
        return viewControllers.reverse()
    }
    
}

class ChronologicalEntryPresenter: EntryPresenter {
    
    override class func presentEntry(entry: Entry, inNavigationController navigationController: UINavigationController, animated: Bool) {
        if let controller = entry.recursiveViewControllerWithNavigationController(navigationController) {
            if navigationController.viewControllers.contains(controller) {
                if navigationController.topViewController != controller {
                    navigationController.popToViewController(controller, animated:animated)
                }
            } else {
                navigationController.pushViewController(controller, animated:animated)
            }
        }
    }
}

class NotificationEntryPresenter: EntryPresenter {
    
    override class func presentEntry(entry: Entry, inNavigationController navigationController: UINavigationController, animated: Bool) {
        var controllers = [UIViewController]()
        
        if let controller = navigationController.viewControllers.first {
            controllers.append(controller)
        }
        
        if let controller = entry.recursiveViewControllerWithNavigationController(navigationController) {
            controllers.append(controller)
        }
        
        navigationController.setViewControllers(controllers, animated:animated)
    }
    
}