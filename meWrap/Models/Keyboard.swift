//
//  Keyboard.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/23/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

final class Keyboard {
    
    static let keyboard = Keyboard()
    
    let willShow = BlockNotifier<Void>()
    let willHide = BlockNotifier<Void>()
    
    var height: CGFloat = 0
    var animationDuration: NSTimeInterval = 0
    var animationCurve: UIViewAnimationCurve = .Linear
    var isShown = false
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(Keyboard.tap(_:)))
    
    init() {
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
        willShow.notify()
    }
    
    func keyboardDidShow(notification: NSNotification) {
        fetchKeyboardMetadata(notification)
        UIWindow.mainWindow.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tap(sender: UITapGestureRecognizer) {
        sender.view?.endEditing(true)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        fetchKeyboardAnimationMetadata(notification)
        willHide.notify()
    }
    
    func keyboardDidHide(notification: NSNotification) {
        height = 0
        animationDuration = 0
        animationCurve = .Linear
        isShown = false
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
    
    func handle(owner: AnyObject, willShow: (keyboard: Keyboard) -> (), willHide: (keyboard: Keyboard) -> ()) {
        self.willShow.subscribe(owner) { _ in willShow(keyboard: Keyboard.keyboard) }
        self.willHide.subscribe(owner) { _ in willHide(keyboard: Keyboard.keyboard) }
    }
}
