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
    
    func createViewController() -> UIViewController {
        return UIViewController()
    }
    
    func createViewControllerIfNeeded() -> UIViewController {
        return UINavigationController.main.viewControllers[{ presentedIn($0) }] ?? createViewController()
    }
    
    func presentedIn(controller: UIViewController) -> Bool {
        return false
    }
}

extension Candy {
    
    override func createViewController() -> UIViewController {
        return specify(HistoryViewController(), { $0.candy = self })
    }
    
    override func presentedIn(controller: UIViewController) -> Bool {
        return (controller as? HistoryViewController)?.candy == self
    }
}

extension Message {
    
    override func createViewController() -> UIViewController {
        if let wrap = wrap {
            let controller = wrap.createViewController() as! WrapViewController
            controller.segment = .Chat
            return controller
        } else {
            return super.createViewController()
        }
    }
    
    override func createViewControllerIfNeeded() -> UIViewController {
        let controller = super.createViewControllerIfNeeded()
        (controller as? WrapViewController)?.segment = .Chat
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
    
    override func createViewController() -> UIViewController {
        return WrapViewController(wrap: self)
    }
    
    override func presentedIn(controller: UIViewController) -> Bool {
        return (controller as? WrapViewController)?.wrap == self
    }
}

extension Comment {
    
    override func createViewController() -> UIViewController {
        if let candy = candy {
            let controller = candy.createViewController() as! HistoryViewController
            performWhenLoaded(controller, block: { $0.showCommentView(false) })
            return controller
        } else {
            return super.createViewController()
        }
    }
    
    override func createViewControllerIfNeeded() -> UIViewController {
        let controller = super.createViewController()
        if let controller = controller as? HistoryViewController {
            performWhenLoaded(controller, block: { $0.showCommentView(false) })
        }
        return controller
    }
}

struct ChronologicalEntryPresenter: EntryPresenter {
    
    static func presentEntry(entry: Entry, animated: Bool) {
        let navigationController = UINavigationController.main
        let controller = entry.createViewControllerIfNeeded()
        if navigationController.viewControllers.contains(controller) {
            if navigationController.topViewController != controller {
                navigationController.popToViewController(controller, animated:animated)
            }
        } else {
            navigationController.pushViewController(controller, animated:animated)
        }
    }
}

struct NotificationEntryPresenter: EntryPresenter {
    
    static func presentEntry(entry: Entry, animated: Bool) {
        let navigationController = UINavigationController.main
        var controllers = Array(navigationController.viewControllers.prefix(1))
        controllers.append(entry.createViewControllerIfNeeded())
        navigationController.setViewControllers(controllers, animated:animated)
    }
}