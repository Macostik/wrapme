//
//  UploaderView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class UploadingView: UIView, NetworkNotifying, EntryNotifying {

    init(contribution: Contribution) {
        super.init(frame: CGRect.zero)
        self.contribution = contribution
        Network.sharedNetwork.addReceiver(self)
        backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        contribution.dynamicType.notifier().addReceiver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var contribution: Contribution?
    
    private var animationImageView: UIImageView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let imageView = animationImageView {
                imageView.center = width / 2 ^ height / 2
                addSubview(imageView)
                imageView.startAnimating()
            }
        }
    }

    func update() {
        guard let uploading = uploading else { return }
        if Network.sharedNetwork.reachable {
            if uploading.inProgress {
                animationImageView = UIImageView(image: UIImage.animatedImageNamed("upload_ic_uploading_", duration: 1))
            } else {
                animationImageView = UIImageView(image: UIImage.animatedImageNamed("upload_ic_queue_", duration: 1))
            }
        } else {
            
        }
    }
    
    func networkDidChangeReachability(network: Network) {
        update()
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry == uploading?.contribution
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        update()
    }
}