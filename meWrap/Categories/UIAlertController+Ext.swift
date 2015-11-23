//
//  UIAlertController+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension UIAlertController {
    
    class func alert(message: String?) -> UIAlertController {
        return UIAlertController(title: nil, message: message, preferredStyle: .Alert)
    }
    
    class func alert(title: String?, message: String?) -> UIAlertController {
        return UIAlertController(title: title, message: message, preferredStyle: .Alert)
    }
    
    class func actionSheet(title: String?) -> UIAlertController {
        return UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
    }
    
    class func actionSheet(title: String?, message: String?) -> UIAlertController {
        return UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
    }
    
    func action(title: String?) -> UIAlertController {
        return action(title, handler: nil)
    }
    
    func action(title: String?, style: UIAlertActionStyle) -> UIAlertController {
        return action(title, style: style, handler: nil)
    }
    
    func action(title: String?, handler: (UIAlertAction -> Void)?) -> UIAlertController {
        return action(title, style: .Default, handler: handler)
    }
    
    func action(title: String?, style: UIAlertActionStyle, handler: (UIAlertAction -> Void)?) -> UIAlertController {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        addAction(action)
        return self
    }
    
    func show () {
        show(nil)
    }
    
    func show(sender: UIView?) {
        if let window = UIWindow.mainWindow {
            if let presentingViewController = window.rootViewController?.presentedViewController ?? window.rootViewController {
                
                if actions.count == 0 {
                    action("ok".ls)
                }
                if let popoverController = self.popoverPresentationController where self.preferredStyle == .ActionSheet {
                    popoverController.sourceView = sender ?? window
                    popoverController.sourceRect = sender?.bounds ?? CGRectMake(window.x, CGRectGetMidY(window.frame) - 1, window.width, 1)
                    popoverController.permittedArrowDirections = .Any
                }
                presentingViewController.presentViewController(self, animated: true, completion: nil)
            }
        }
    }
}

extension UIAlertController {
    
    class func confirmWrapDeleting(wrap: Wrap, success: (UIAlertAction -> Void)?, failure: (UIAlertAction -> Void)?) {
        let controller: UIAlertController!
        if wrap.deletable {
            controller = alert("delete_wrap".ls, message: String(format: "formatted_delete_wrap_confirmation".ls, wrap.name ?? ""))
            controller.action("cancel".ls, handler: failure)
            controller.action("delete".ls, handler: success)
        } else {
            if (wrap.isPublic) {
                controller = alert("unfollow_confirmation_title".ls, message: "unfollow_confirmation_message".ls)
                controller.action("uppercase_no".ls, handler: failure)
                controller.action("uppercase_yes".ls, handler: success)
            } else {
                controller = alert("leave_wrap".ls, message: String(format: "leave_wrap_confirmation".ls, wrap.name ?? ""))
                controller.action("uppercase_no".ls, handler: failure)
                controller.action("uppercase_yes".ls, handler: success)
            }
        }
        controller.show()
    }
    
    class func confirmCandyDeleting(candy: Candy, success: (UIAlertAction -> Void)?, failure: (UIAlertAction -> Void)?) {
        let controller = alert("delete_photo".ls, message: (candy.isVideo ? "delete_video_confirmation" : "delete_photo_confirmation").ls)
        controller.action("cancel".ls, handler: failure)
        controller.action("ok".ls, handler: success)
        controller.show()
    }
    
    class func confirmRedirectingToSignUp(signUp: (UIAlertAction -> Void)?, tryAgain: (UIAlertAction -> Void)?) {
        let controller = alert("authorization_error_title".ls, message: "authorization_error_message".ls)
        controller.action("try_again".ls, handler: tryAgain)
        controller.action("authorization_error_sign_up".ls, handler: signUp)
        controller.show()
    }
}