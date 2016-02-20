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

class WrapSegmentViewController: WLBaseViewController {
    weak var delegate: AnyObject?
    weak var wrap: Wrap!
    weak var badge: BadgeLabel?
}

final class FriendView: StreamReusableView {
    
    private var avatarView = ImageView(backgroundColor: UIColor.whiteColor())
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        avatarView.cornerRadius = 16
        avatarView.defaultBackgroundColor = Color.grayLighter
        avatarView.defaultIconColor = UIColor.whiteColor()
        avatarView.defaultIconText = "&"
        addSubview(avatarView)
        avatarView.snp_makeConstraints(closure: {
            $0.width.height.equalTo(32)
            $0.centerY.equalTo(self)
            $0.trailing.equalTo(self)
        })
    }
    
    override func setup(entry: AnyObject?) {
        if let friend = entry as? User {
            let url = friend.avatar?.small
            if !friend.isInvited && url?.isEmpty ?? true {
                avatarView.defaultBackgroundColor = Color.orange
            } else {
                avatarView.defaultBackgroundColor = Color.grayLighter
            }
            avatarView.url = url
        }
    }
}

final class WrapSegmentButton: SegmentButton {
    
    @IBInspectable var icon: String? {
        willSet {
            iconLabel.text = newValue
        }
    }
    
    @IBInspectable var text: String? {
        willSet {
            textLabel.text = newValue?.ls
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        badge.clipsToBounds = true
        badge.textAlignment = .Center
        badge.backgroundColor = Color.dangerRed
        badge.hidden = true
        selectionView.hidden = true
        selectionView.backgroundColor = Color.orange
        iconLabel.highlightedTextColor = Color.orange
        textLabel.highlightedTextColor = Color.orange
        let view = UIView()
        view.userInteractionEnabled = false
        addSubview(view)
        view.addSubview(iconLabel)
        view.addSubview(textLabel)
        addSubview(selectionView)
        addSubview(badge)
        view.snp_makeConstraints { $0.center.equalTo(self) }
        iconLabel.snp_makeConstraints { $0.leading.top.bottom.equalTo(view) }
        textLabel.snp_makeConstraints {
            $0.leading.equalTo(iconLabel.snp_trailing).offset(5)
            $0.trailing.centerY.equalTo(view)
        }
        badge.snp_makeConstraints(closure: {
            $0.bottom.equalTo(view.snp_centerY).offset(-1)
            $0.leading.equalTo(iconLabel.snp_trailing).inset(10)
            $0.width.greaterThanOrEqualTo(badge.snp_height)
        })
        selectionView.snp_makeConstraints {
            $0.leading.trailing.bottom.equalTo(self)
            $0.height.equalTo(4)
        }
        badge.circled = true
    }
    
    var badge = BadgeLabel(preset: .Smaller, weight: UIFontWeightRegular, textColor: UIColor.whiteColor())
    
    private var selectionView = UIView()
    
    private var iconLabel = Label(icon: "", size: 24, textColor: Color.grayLighter)
    
    private var textLabel = Label(preset: .Normal, weight: UIFontWeightRegular, textColor: Color.grayLighter)
    
    override var selected: Bool {
        willSet {
            selectionView.hidden = !newValue
            iconLabel.highlighted = newValue
            textLabel.highlighted = newValue
        }
    }
}

final class WrapViewController: WLBaseViewController {
    
    weak var wrap: Wrap?
    
    var segment: WrapSegment = .Media {
        didSet {
            if isViewLoaded() && segment != oldValue {
                updateSegment()
            }
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var inboxSegmentButton: WrapSegmentButton!
    
    @IBOutlet weak var mediaSegmentButton: WrapSegmentButton!
    
    @IBOutlet weak var chatSegmentButton: WrapSegmentButton!
    
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
    @IBOutlet weak var friendsStreamView: StreamView!
    
    @IBOutlet var publicWrapPrioritizer: LayoutPrioritizer!
    
    private var wrapNotifyReceiver: EntryNotifyReceiver?
    
    private lazy var friendsDataSource: StreamDataSource = StreamDataSource(streamView: self.friendsStreamView)
    
    @IBOutlet weak var moreFriendsLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addNotifyReceivers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsStreamView.horizontal = true
        let size = (view.width - moreFriendsLabel.width) / ((view.width - moreFriendsLabel.width) / friendsStreamView.height)
        friendsDataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<FriendView>(), size: size))
        
        guard let wrap = wrap where wrap.valid else { return }
        
        let chatViewController = controllerForSegment(.Chat)
        if !chatViewController.isViewLoaded() {
            let _ = chatViewController.view
        }
        
        segmentedControl.deselect()
        
        settingsButton.exclusiveTouch = true
        followButton.exclusiveTouch = true
        unfollowButton.exclusiveTouch = true
        
        APIRequest.contributors(wrap).send({ [weak self] _ in
            self?.updateFriendsBar(wrap)
            }, failure: nil)
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
            updateSegment()
        }
    }
    
    private func updateSegment() {
        segmentedControl.selectedSegment = segment.rawValue
        viewController = controllerForSegment(segment)
        updateInboxCounter()
    }
    
    func presentLiveProadcast(broadcast: LiveBroadcast) {
        segment = .Media
        let controller = controllerForSegment(.Media) as? MediaViewController
        controller?.presentLiveBroadcast(broadcast)
    }
    
    private func controllerForSegment(segment: WrapSegment) -> WrapSegmentViewController {
        switch segment {
        case .Inbox: return controllerNamed("inbox", badge:self.inboxSegmentButton.badge)
        case .Media: return controllerNamed("media", badge:self.mediaSegmentButton.badge)
        case .Chat: return controllerNamed("chat", badge:self.chatSegmentButton.badge)
        }
    }
    
    private func addNotifyReceivers() {
        
        wrapNotifyReceiver = Wrap.notifyReceiver().setup({ [unowned self] (receiver) -> Void in
            receiver.entry = { return self.wrap }
            receiver.didUpdate = { entry, event in
                if event == .NumberOfUnreadMessagesChanged {
                    if self.segment != .Chat {
                        self.chatSegmentButton.badge.value = self.wrap?.numberOfUnreadMessages ?? 0
                    }
                } else if event == .InboxChanged {
                    self.updateInboxCounter()
                    self.updateMessageCouter()
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
        
        updateFriendsBar(wrap)
    }
    
    private func updateFriendsBar(wrap: Wrap) {
        let maxFriendsCount = Int((view.width - moreFriendsLabel.width) / friendsStreamView.height)
        let contributors = wrap.contributors.sort {
            if $0.current || ($0.avatar?.small?.isEmpty ?? true) {
                return false
            } else if $1.current || ($1.avatar?.small?.isEmpty ?? true) {
                return true
            } else {
                return $0.name < $1.name
            }
            }.prefix(maxFriendsCount)
        moreFriendsLabel.hidden = wrap.contributors.count <= maxFriendsCount
        friendsDataSource.items = Array(contributors)
    }
    
    private func followingStateForWrap(wrap: Wrap) {
        followButton.hidden = !wrap.requiresFollowing || wrap.contributor?.current == true
        unfollowButton.hidden = !followButton.hidden
    }
    
    private func updateMessageCouter() {
        chatSegmentButton.badge.value = wrap?.numberOfUnreadMessages ?? 0
    }
    
    private func updateInboxCounter() {
        inboxSegmentButton.badge.value = wrap?.numberOfUnreadInboxItems ?? 0
    }
    
    var showKeyboard = false {
        didSet {
            if let controller = viewController as? ChatViewController where showKeyboard {
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
                    (controller as? ChatViewController)?.showKeyboard = showKeyboard
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
    
    private func controllerNamed(name: String, badge: BadgeLabel?) -> WrapSegmentViewController {
        var controller: WrapSegmentViewController! = childViewControllers.filter { $0.restorationIdentifier == name }.first as? WrapSegmentViewController
        if controller == nil {
            controller = storyboard?[name] as! WrapSegmentViewController
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
        segment = WrapSegment(rawValue: sender.selectedSegment)!
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
    
    @IBAction func showFriends(sender: AnyObject) {
        let controller = Storyboard.Friends.instantiate()
        controller.wrap = wrap
        navigationController?.pushViewController(controller, animated: false)
    }
}

extension WrapViewController: CaptureMediaViewControllerDelegate {
    
    func captureViewController(controller: CaptureMediaViewController, didFinishWithAssets assets: [MutableAsset]) {
        let wrap = controller.wrap ?? self.wrap
        if self.wrap != wrap {
            self.view = nil
            self.viewController = nil
            for controller in childViewControllers where controller is WrapSegmentViewController {
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
