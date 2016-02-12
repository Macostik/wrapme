//
//  WrapViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/12/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

@objc enum WrapSegment: Int {
    case Inbox, Media, Chat
}

class WrapViewController: WLBaseViewController {
    
    weak var wrap: Wrap?
    
    var segment: WrapSegment = .Media
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageCountLabel: BadgeLabel!
    @IBOutlet weak var candyCountLabel: BadgeLabel!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var unfollowButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var publicWrapView: UIView!
    @IBOutlet weak var publicWrapImageView: WrapCoverView!
    @IBOutlet weak var creatorName: UILabel!
    @IBOutlet weak var publicWrapNameLabel: UILabel!
    @IBOutlet weak var ownerDescriptionLabel: UILabel!
    @IBOutlet weak var typingLabel: Label!
    
    @IBOutlet var publicWrapPrioritizer: LayoutPrioritizer!
    @IBOutlet var titleViewPrioritizer: LayoutPrioritizer!
    
    private var wrapNotifyReceiver: EntryNotifyReceiver?
    private var candyNotifyReceiver: EntryNotifyReceiver?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addNotifyReceivers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let wrap = wrap where wrap.valid else { return }
        
        let chatViewController = controllerNamed("chat", badge: messageCountLabel)
        if !chatViewController.isViewLoaded() {
            let _ = chatViewController.view
        }
        
        segmentedControl.deselect()
        
        settingsButton.exclusiveTouch = true
        followButton.exclusiveTouch = true
        unfollowButton.exclusiveTouch = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if wrap?.valid == true {
            updateWrapData()
            updateSegmentIfNeeded()
            updateMessageCouter()
        }
    }
    
    private func updateSegmentIfNeeded() {
        if segment.rawValue != segmentedControl.selectedSegment {
            segmentedControl.selectedSegment = segment.rawValue
            segmentChanged(segmentedControl)
        }
    }
    
    func presentLiveProadcast(broadcast: LiveBroadcast) {
        if segment != .Media {
            changeSegment(.Media)
        }
        let controller = controllerNamed("media", badge:self.candyCountLabel) as? MediaViewController
        controller?.presentLiveBroadcast(broadcast)
    }
    
    private func changeSegment(segment: WrapSegment) {
        self.segment = segment
        if segment == .Media {
            viewController = controllerNamed("media", badge:self.candyCountLabel)
        } else if (segment == .Chat) {
            viewController = controllerNamed("chat", badge:self.messageCountLabel)
        } else {
            viewController = controllerNamed("friends", badge:nil)
        }
        updateCandyCounter()
    }
    
    private func addNotifyReceivers() {
        
        wrapNotifyReceiver = Wrap.notifyReceiver().setup({ [unowned self] (receiver) -> Void in
            receiver.entry = { return self.wrap }
            receiver.didUpdate = { entry, event in
                if event == .NumberOfUnreadMessagesChanged {
                    if self.segment != .Chat {
                        self.messageCountLabel.value = self.wrap?.numberOfUnreadMessages ?? 0
                    }
                } else {
                    self.updateWrapData()
                }
            }
            receiver.willDelete = { entry in
                if self.viewAppeared {
                    self.navigationController?.popToRootViewControllerAnimated(false)
                    Toast.showMessageForUnavailableWrap(entry as? Wrap)
                }
            }
            })
        
        candyNotifyReceiver = Candy.notifyReceiver().setup({ [unowned self] (receiver) -> Void in
            receiver.container = { self.wrap }
            receiver.didAdd = { entry in
                if self.isViewLoaded() && self.segment == .Media {
                    entry.markAsUnread(false)
                }
            }
            })
        
        RecentUpdateList.sharedList.addReceiver(self)
    }
    
    private func updateWrapData() {
        guard let wrap = wrap else { return }
        nameLabel.text = wrap.name
        if wrap.isPublic {
            followingStateForWrap(wrap)
            let contributorIsCurrent = wrap.contributor?.current == true
            publicWrapImageView.url = wrap.contributor?.avatar?.small
            publicWrapImageView.isFollowed = wrap.isContributing
            publicWrapImageView.isOwner = contributorIsCurrent
            creatorName.text = wrap.contributor?.name
            let requiresFollowing = wrap.requiresFollowing
            segmentedControl.hidden = true
            settingsButton.hidden = requiresFollowing
            publicWrapView.hidden = false
            publicWrapPrioritizer.defaultState = true
            publicWrapNameLabel.text = wrap.name
            ownerDescriptionLabel.hidden = !contributorIsCurrent
        } else {
            segmentedControl.hidden = false
            settingsButton.hidden = false
            publicWrapView.hidden = true
            publicWrapPrioritizer.defaultState = false
        }
    }
    
    private func followingStateForWrap(wrap: Wrap) {
        followButton.hidden = !wrap.requiresFollowing || wrap.contributor?.current == true
        unfollowButton.hidden = !followButton.hidden
    }
    
    private func updateMessageCouter() {
        messageCountLabel.value = wrap?.numberOfUnreadMessages ?? 0
    }
    
    private func updateCandyCounter() {
        candyCountLabel.value = wrap?.numberOfUnreadCandies ?? 0
    }
    
    var showKeyboard = false {
        didSet {
            if let controller = viewController as? WLChatViewController where showKeyboard {
                controller.showKeyboard = showKeyboard
                if controller.isViewLoaded() {
                    showKeyboard = false
                }
            }
        }
    }
    
    private var viewController: UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let controller = viewController {
                if segment == .Chat {
                    (controller as? WLChatViewController)?.showKeyboard = showKeyboard
                    showKeyboard = false
                }
                
                let view = controller.view
                view.translatesAutoresizingMaskIntoConstraints = false
                view.frame = self.containerView.bounds
                containerView.addSubview(view)
                view.snp_makeConstraints(closure: { $0.edges.equalTo(containerView) })
                view.setNeedsLayout()
            }
        }
    }
    
    private func controllerNamed(name: String, badge: BadgeLabel?) -> WLWrapEmbeddedViewController {
        var controller: WLWrapEmbeddedViewController! = childViewControllers.filter { $0.restorationIdentifier == name }.first as? WLWrapEmbeddedViewController
        if controller == nil {
            controller = storyboard?[name] as! WLWrapEmbeddedViewController
            controller.preferredViewFrame = containerView.bounds
            controller.wrap = wrap
            controller.delegate = self
            addChildViewController(controller)
            controller.didMoveToParentViewController(self)
        }
        controller.badge = badge
        return controller
    }
}

extension WrapViewController {
    
    @IBAction func segmentChanged(sender: SegmentedControl) {
        changeSegment(WrapSegment(rawValue: sender.selectedSegment)!)
    }
    
    @IBAction func follow(sender: Button) {
        guard let wrap = wrap else { return }
        sender.loading = true
        RunQueue.fetchQueue.run { [weak self] (finish) -> Void in
            APIRequest.followWrap(wrap).send({ (_) -> Void in
                self?.followingStateForWrap(wrap)
                sender.loading = false
                finish()
                }, failure: { (error) -> Void in
                    error?.show()
                    sender.loading = false
                    finish()
            })
        }
    }
    
    @IBAction func unfollow(sender: Button) {
        guard let wrap = wrap else { return }
        self.settingsButton.userInteractionEnabled = false
        sender.loading = true
        RunQueue.fetchQueue.run { [weak self] (finish) -> Void in
            APIRequest.unfollowWrap(wrap).send({ (_) -> Void in
                self?.followingStateForWrap(wrap)
                sender.loading = false
                self?.settingsButton.userInteractionEnabled = true
                finish()
                }, failure: { (error) -> Void in
                    error?.show()
                    sender.loading = false
                    self?.settingsButton.userInteractionEnabled = true
                    finish()
            })
        }
    }
}

extension WrapViewController: CaptureMediaViewControllerDelegate {
    
    func captureViewController(controller: CaptureMediaViewController, didFinishWithAssets assets: [MutableAsset]) {
        let wrap = controller.wrap ?? self.wrap
        if self.wrap != wrap {
            self.view = nil
            self.viewController = nil
            for controller in childViewControllers where controller is WLWrapEmbeddedViewController {
                controller.removeFromParentViewController()
            }
            self.wrap = wrap
        }
        
        dismissViewControllerAnimated(false, completion: nil)
        
        FollowingViewController.followWrapIfNeeded(wrap) {
            SoundPlayer.player.play(.s04)
            wrap?.uploadAssets(assets)
        }
    }
    
    func captureViewControllerDidCancel(controller: CaptureMediaViewController) {
        dismissViewControllerAnimated(false, completion: nil)
    }
}

extension WrapViewController: MediaViewControllerDelegate {
    
    func mediaViewControllerDidAddPhoto(controller: MediaViewController) {
        let captureViewController = CaptureViewController.captureMediaViewController(wrap)
        captureViewController.captureDelegate = self
        presentViewController(captureViewController, animated: false, completion: nil)
    }
}

extension WrapViewController: RecentUpdateListNotifying {
    
    func recentUpdateListUpdated(list: RecentUpdateList) {
        updateCandyCounter()
        updateMessageCouter()
    }
}
