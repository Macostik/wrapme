//
//  UploaderView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class UploaderView: UIView {

    var uploader: Uploader? {
        didSet {
            uploader?.addReceiver(self)
            Network.sharedNetwork.addReceiver(self)
        }
    }
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var arrowIcon: UIButton!
    
    private var animation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(CATransform3D:CATransform3DMakeTranslation(0, -3, 0))
        animation.fromValue = NSValue(CATransform3D:CATransform3DMakeTranslation(0, -7, 0))
        animation.duration = 1.0
        animation.repeatCount = FLT_MAX
        return animation
    }()

    func update() {
        if let uploader = uploader {
            update(uploader)
        }
    }
    
    private func update(uploader: Uploader) {
        addAnimation(CATransition.transition(kCATransitionFade))
        hidden = uploader.isEmpty
        if !hidden {
            countLabel.text = "\(uploader.count)"
            let networkReachable = Network.sharedNetwork.reachable
            backgroundColor = (networkReachable ? Color.orange : Color.grayLight).colorWithAlphaComponent(0.8)
            arrowIcon.setTitleColor(backgroundColor, forState: .Normal)
            if networkReachable {
                startAnimating()
            } else {
                stopAnimating()
            }
        } else {
            stopAnimating()
        }
    }
    
    private func startAnimating() {
        if arrowIcon.layer.animationForKey("uploading") != nil {
            arrowIcon.layer.addAnimation(animation, forKey: "uploading")
        }
    }
    
    private func stopAnimating() {
        arrowIcon.layer.removeAnimationForKey("uploading")
    }
}

extension UploaderView: UploaderNotifying {
    func uploaderDidStart(uploader: Uploader) {
        update(uploader)
    }
    func uploaderDidChange(uploader: Uploader) {
        update(uploader)
    }
    func uploaderDidStop(uploader: Uploader) {
        update(uploader)
    }
}

extension UploaderView: NetworkNotifying {
    func networkDidChangeReachability(network: Network) {
        update()
    }
}
