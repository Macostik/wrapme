//
//  UploaderView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

enum UploadingViewState {
    case Ready, InProgress, Finished, Offline, None
}

class UploadingView: UIView, NetworkNotifying, EntryNotifying {
    
    init(contribution: Contribution) {
        super.init(frame: CGRect.zero)
        self.contribution = contribution
        Network.sharedNetwork.addReceiver(self)
        backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        contribution.dynamicType.notifier().addReceiver(self)
        contentView.borderWidth = 2
        contentView.clipsToBounds = true
        addSubview(contentView)
        contentView.snp_makeConstraints { $0.center.equalTo(self) }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var contribution: Contribution?
    
    private let contentView = UIView()
    
    private var animationImageView: UIImageView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let imageView = animationImageView {
                contentView.addSubview(imageView)
                imageView.snp_makeConstraints(closure: { $0.edges.equalTo(contentView) })
                contentView.layoutIfNeeded()
                contentView.cornerRadius = contentView.height/2
            }
        }
    }
    
    private func awakeFromOffline(animate: Bool, block: () -> ()) {
        if let animationImageView = animationImageView where animate {
            UIView.transitionWithView(animationImageView, duration: 0.5, options: .TransitionFlipFromLeft, animations: {
                self.contentView.borderColor = Color.orange
                animationImageView.image = UIImage(named: "upload_ic_wifi_online")
                }, completion: { (_) in
                    Dispatch.mainQueue.after(0.5, block: { () in
                        block()
                    })
            })
        } else {
            block()
        }
    }
    
    weak var progressBar: ProgressBar?
    
    var state: UploadingViewState = .None {
        didSet {
            guard state != oldValue else { return }
            switch state {
            case .Ready:
                awakeFromOffline(oldValue == .Offline, block: {
                    if self.state == .Ready {
                        self.contentView.borderColor = UIColor.clearColor()
                        self.animationImageView = specify(UIImageView(), {
                            $0.animationImages = UIImage.animatedImageNamed("upload_ic_queue_", duration: 1)?.images
                            $0.startAnimating()
                        })
                        self.contentView.addAnimation(CATransition.transition(kCATransitionFade))
                    }
                })
            case .InProgress:
                awakeFromOffline(oldValue == .Offline, block: {
                    if self.state == .InProgress {
                        self.contentView.borderColor = UIColor.clearColor()
                        let animationImageView = specify(UIImageView(), {
                            $0.animationImages = UIImage.animatedImageNamed("upload_ic_uploading_", duration: 1)?.images
                            $0.startAnimating()
                        })
                        self.animationImageView = animationImageView
                        self.contentView.addAnimation(CATransition.transition(kCATransitionFade))
                        let progressBar = ProgressBar()
                        animationImageView.addSubview(progressBar)
                        progressBar.snp_makeConstraints(closure: { (make) in
                            make.edges.equalTo(animationImageView).inset(1)
                        })
                        self.progressBar = progressBar
                    }
                })
            case .Finished:
                contentView.borderColor = UIColor.clearColor()
                animationImageView = specify(UIImageView(), {
                    $0.animationImages = UIImage.animatedImageNamed("upload_ic_success_", duration: 1)?.images
                    $0.image = $0.animationImages?.last
                    $0.animationRepeatCount = 1
                    $0.startAnimating()
                })
                Dispatch.mainQueue.after(1.5, block: { () in
                    UIView.animateWithDuration(0.5, animations: {
                        self.alpha = 0
                        }, completion: { (_) in
                            self.contribution?.uploadingView = nil
                            self.removeFromSuperview()
                    })
                })
            case .Offline:
                contentView.borderColor = Color.grayLighter
                animationImageView = UIImageView(image: UIImage(named: "upload_ic_wifi_offline"))
            case .None:
                animationImageView = nil
            }
        }
    }
    
    func updateProgress(progress: CGFloat) {
        progressBar?.setProgress(progress, animated: true)
    }
    
    func update() {
        guard let contribution = contribution else { return }
        if Network.sharedNetwork.reachable {
            switch contribution.statusOfAnyUploadingType() {
            case .Ready:
                state = .Ready
            case .InProgress:
                state = .InProgress
            case .Finished:
                state = .Finished
            }
        } else {
            state = .Offline
        }
    }
    
    func networkDidChangeReachability(network: Network) {
        update()
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry == contribution
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        update()
    }
}