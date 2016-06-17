//
//  EntryPresenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

protocol EntryPresenter {
    static func presentEntry(entry: Entry, animated: Bool)
}

extension EntryPresenter {
    
    static func presentEntryWithPermission(entry: Entry, animated: Bool, completionHandler: (() -> ())? = nil) {
        let navigationController = UINavigationController.main
        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.requestPresentingPermission({ (flag) -> Void in
                if (flag) {
                    navigationController.dismissViewControllerAnimated(false, completion: { () -> Void in
                        self.presentEntry(entry, animated:animated)
                        completionHandler?()
                    })
                } else {
                    completionHandler?()
                }
            })
        } else if let topViewController = navigationController.topViewController {
            topViewController.requestPresentingPermission({ (flag) -> Void in
                if (flag) {
                    self.presentEntry(entry, animated:animated)
                    completionHandler?()
                } else {
                    completionHandler?()
                }
            })
        } else {
            self.presentEntry(entry, animated:animated)
            completionHandler?()
        }
    }
}

extension UIViewController {
    func requestPresentingPermission(completion: BooleanBlock) {
        completion(true)
    }
}

extension Entry {
    
    func createViewController() -> UIViewController? {
        return nil
    }
    
    func createViewControllerIfNeeded() -> UIViewController? {
        return UINavigationController.main.viewControllers[{ presentedIn($0) }] ?? createViewController()
    }
    
    func recursiveViewController() -> UIViewController? {
        var _currentEntry: Entry? = self
        while let currentEntry = _currentEntry where currentEntry.valid {
            if let controller = currentEntry.createViewControllerIfNeeded() {
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
    
    func presentedIn(controller: UIViewController) -> Bool {
        return false
    }
    
    func configureViewController(controller: UIViewController, fromContainer container: Entry) {}
}

extension Candy {
    
    override func createViewController() -> UIViewController? {
        return specify(HistoryViewController(), { $0.candy = self })
    }
    
    override func presentedIn(controller: UIViewController) -> Bool {
        return (controller as? HistoryViewController)?.candy == self
    }
}

extension Message {
    
    override func createViewController() -> UIViewController? {
        let controller = wrap?.createViewController() as? WrapViewController
        controller?.segment = .Chat
        return controller
    }
    
    override func createViewControllerIfNeeded() -> UIViewController? {
        let controller = super.createViewControllerIfNeeded()
        if let controller = controller as? WrapViewController {
            controller.segment = .Chat
        }
        return controller
    }
    
    override func presentedIn(controller: UIViewController) -> Bool {
        guard let _wrap = (controller as? WrapViewController)?.wrap where _wrap == wrap else {
            return false
        }
        return true
    }
}

extension Wrap {
    
    override func createViewController() -> UIViewController? {
        return WrapViewController(wrap: self)
    }
    
    override func presentedIn(controller: UIViewController) -> Bool {
        return (controller as? WrapViewController)?.wrap == self
    }
}

extension Comment {
    
    override func configureViewController(controller: UIViewController, fromContainer container: Entry) {
        if container == candy, let controller = controller as? HistoryViewController {
            performWhenLoaded(controller, block: { $0.showCommentView(false) })
        }
    }
}

struct HierarchicalEntryPresenter: EntryPresenter {
    
    static func presentEntry(entry: Entry, animated: Bool) {
        let navigationController = UINavigationController.main
        var viewControllers = self.viewControllersForEntry(entry)
        if let controller = navigationController.viewControllers.first {
            viewControllers.insert(controller, atIndex: 0)
        }
        navigationController.setViewControllers(viewControllers, animated:animated)
    }
    
    static func viewControllersForEntry(entry: Entry) -> [UIViewController] {
        var viewControllers = [UIViewController]()
        var _currentEntry: Entry? = entry
        while let currentEntry = _currentEntry where currentEntry.valid {
            if let controller = currentEntry.createViewControllerIfNeeded() {
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

struct ChronologicalEntryPresenter: EntryPresenter {
    
    static func presentEntry(entry: Entry, animated: Bool) {
        let navigationController = UINavigationController.main
        if let controller = entry.recursiveViewController() {
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

struct NotificationEntryPresenter: EntryPresenter {
    
    static func presentEntry(entry: Entry, animated: Bool) {
        let navigationController = UINavigationController.main
        var controllers = [UIViewController]()
        
        if let controller = navigationController.viewControllers.first {
            controllers.append(controller)
        }
        
        if let controller = entry.recursiveViewController() {
            controllers.append(controller)
        }
        
        navigationController.setViewControllers(controllers, animated:animated)
    }
    
}