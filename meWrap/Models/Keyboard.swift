//
//  Keyboard.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol KeyboardNotifying {
    optional func keyboardWillShow(keyboard: Keyboard)
    optional func keyboardDidShow(keyboard: Keyboard)
    optional func keyboardWillHide(keyboard: Keyboard)
    optional func keyboardDidHide(keyboard: Keyboard)
}

class Keyboard: Notifier {
    
    static let keyboard = Keyboard()
    
    var height: CGFloat = 0
    var animationDuration: NSTimeInterval = 0
    var animationCurve: UIViewAnimationCurve = .Linear
    var isShown = false
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tap:")
    
    override init() {
        super.init()
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        center.addObserverForName(UIKeyboardWillShowNotification, object: nil, queue: queue, usingBlock: keyboardWillShow)
        center.addObserverForName(UIKeyboardDidShowNotification, object: nil, queue: queue, usingBlock: keyboardDidShow)
        center.addObserverForName(UIKeyboardWillHideNotification, object: nil, queue: queue, usingBlock: keyboardWillHide)
        center.addObserverForName(UIKeyboardDidHideNotification, object: nil, queue: queue, usingBlock: keyboardDidHide)
    }
    
    private func fetchKeyboardAnimationMetadata(notification: NSNotification) {
        let userInfo = notification.userInfo
        animationDuration = userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval ?? 0
        if let curve = userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int {
            animationCurve = UIViewAnimationCurve(rawValue: curve) ?? .Linear
        } else {
            animationCurve = .Linear
        }
    }
    
    private func fetchKeyboardMetadata(notification: NSNotification) {
        let userInfo = notification.userInfo
        let rect = (userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
        height = rect?.size.height ?? 0
        fetchKeyboardAnimationMetadata(notification)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        fetchKeyboardMetadata(notification)
        isShown = true
        notify { $0.keyboardWillShow?(self) }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        fetchKeyboardMetadata(notification)
        notify { $0.keyboardDidShow?(self) }
        UIWindow.mainWindow.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func tap(sender: UITapGestureRecognizer) {
        sender.view?.endEditing(true)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        fetchKeyboardAnimationMetadata(notification)
        notify { $0.keyboardWillHide?(self) }
    }
    
    func keyboardDidHide(notification: NSNotification) {
        height = 0
        animationDuration = 0
        animationCurve = .Linear
        isShown = false
        notify { $0.keyboardDidHide?(self) }
        tapGestureRecognizer.view?.removeGestureRecognizer(tapGestureRecognizer)
    }
    
    func performAnimation( @noescape animation: Block) {
        UIView.beginAnimations(nil, context:nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        animation()
        UIView.commitAnimations()
    }
}
