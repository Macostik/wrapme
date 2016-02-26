//
//  FollowingViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class FollowingViewController: BaseViewController {
    
    weak var wrap: Wrap?
    
    private var actionBlock: Block?
    
    private var window: UIWindow?
    
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var laterButton: UIButton!
    @IBOutlet weak var imageView: WrapCoverView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    class func followWrapIfNeeded(wrap: Wrap?, performAction action: Block) {
        guard let wrap = wrap?.validEntry() else { return }
        if (wrap.requiresFollowing) {
            if let controller = UIStoryboard.main()["FollowingViewController"] as? FollowingViewController {
                controller.wrap = wrap
                controller.actionBlock = action
                let window = UIWindow(frame:UIScreen.mainScreen().bounds)
                window.rootViewController = controller
                window.makeKeyAndVisible()
                controller.window = window
            } else {
                action()
            }
        } else {
            action()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateState()
    }
    
    private func updateState() {
        guard let wrap = wrap else { return }
        let requiresFollowing = wrap.requiresFollowing
        followButton.hidden = !requiresFollowing
        laterButton.hidden = !requiresFollowing
        closeButton.hidden = requiresFollowing
        nameLabel.text = wrap.name
        ownerLabel.text = wrap.contributor?.name
        imageView.url = wrap.asset?.small
        imageView.isFollowed = wrap.isPublic && wrap.isContributing
        imageView.isOwner = wrap.contributor?.current ?? false
        messageLabel.text = (requiresFollowing ? "follow_wrap_suggestion" : "followed_wrap_suggestion").ls
    }
    
    @IBAction func close(sender: UIButton) {
        actionBlock?()
        self.window?.rootViewController = nil;
        self.window?.hidden = true
    }
    
    @IBAction func later(sender: UIButton) {
        self.window?.rootViewController = nil;
        self.window?.hidden = true
    }
    
    @IBAction func follow(sender: Button) {
        guard let wrap = wrap else { return }
        sender.loading = true
        APIRequest.followWrap(wrap).send({ [weak self] (_) -> Void in
            self?.updateState()
            sender.loading = false
            }) { (error) -> Void in
                sender.loading = false
                error?.show()
        }
    }
}
