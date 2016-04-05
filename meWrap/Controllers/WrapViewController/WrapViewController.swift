//
//  WrapViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/12/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

enum WrapSegment: Int {
    case Inbox, Media, Chat
}

class WrapSegmentViewController: BaseViewController {
    weak var delegate: AnyObject?
    weak var wrap: Wrap!
    weak var badge: BadgeLabel?
}

final class WrapSegmentButton: Button {
    
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
        badge.intrinsicContentSizeInsets = CGSize(width: 5, height: 5)
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
    
    var badge = BadgeLabel(preset: .Smaller, weight: .Regular, textColor: UIColor.whiteColor())
    
    private var selectionView = UIView()
    
    private var iconLabel = Label(icon: "", size: 24, textColor: Color.grayLighter)
    
    private var textLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayLighter)
    
    override var selected: Bool {
        willSet {
            selectionView.hidden = !newValue
            iconLabel.highlighted = newValue
            textLabel.highlighted = newValue
        }
    }
}

final class WrapViewController: BaseViewController {
    
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
    
    private var wrapNotifyReceiver: EntryNotifyReceiver<Wrap>?
    
    private var userNotifyReceiver: EntryNotifyReceiver<User>?
    
    private lazy var friendsDataSource: StreamDataSource = StreamDataSource(streamView: self.friendsStreamView)
    
    @IBOutlet weak var moreFriendsLabel: UILabel!
    
    lazy var inboxViewController: InboxViewController = self.controllerNamed("inbox", badge:self.inboxSegmentButton.badge)
    lazy var mediaViewController: MediaViewController = self.controllerNamed("media", badge:self.mediaSegmentButton.badge)
    lazy var chatViewController: ChatViewController = self.controllerNamed("chat", badge:self.chatSegmentButton.badge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addNotifyReceivers()
        
        friendsStreamView.layout = HorizontalStreamLayout()
        let friendMetrics = StreamMetrics(loader: StreamLoader<FriendView>(), size: friendsStreamView.height)
        friendMetrics.prepareAppearing = { [weak self] item, view in
            (view as? FriendView)?.wrap = self?.wrap
        }
        friendsDataSource.addMetrics(friendMetrics)
        guard let wrap = wrap where wrap.valid else { return }
        
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
    
    func presentLiveBroadcast(broadcast: LiveBroadcast) {
        segment = .Media
        performWhenLoaded(self) {
            performWhenLoaded($0.mediaViewController, block: {
                $0.presentLiveBroadcast(broadcast)
            })
        }
    }
    
    private func controllerForSegment(segment: WrapSegment) -> WrapSegmentViewController {
        switch segment {
        case .Inbox: return inboxViewController
        case .Media: return mediaViewController
        case .Chat: return chatViewController
        }
    }
    
    private func addNotifyReceivers() {
        
        wrapNotifyReceiver = EntryNotifyReceiver<Wrap>().setup({ [weak self] (receiver) -> Void in
            receiver.entry = { return self?.wrap }
            receiver.didUpdate = { entry, event in
                if event == .NumberOfUnreadMessagesChanged {
                    if self?.segment != .Chat {
                        self?.chatSegmentButton.badge.value = self?.wrap?.numberOfUnreadMessages ?? 0
                    }
                } else if event == .InboxChanged {
                    self?.updateInboxCounter()
                    self?.updateMessageCouter()
                } else {
                    self?.updateWrapData()
                }
            }
            receiver.willDelete = { entry in
                if self?.viewAppeared == true {
                    self?.navigationController?.popToRootViewControllerAnimated(false)
                    InfoToast.showMessageForUnavailableWrap(entry)
                }
            }
            })
        
        userNotifyReceiver = EntryNotifyReceiver<User>().setup({ [weak self] (receiver) -> Void in
            receiver.shouldNotify = { user in
                return self?.wrap?.contributors.contains(user) ?? false
            }
            receiver.didUpdate = { entry, event in
                if event == .UserStatus {
                    if let wrap = self?.wrap {
                        self?.updateFriendsBar(wrap)
                    }
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
        let maxFriendsCount = Int((Constants.screenWidth - moreFriendsLabel.width) / friendsStreamView.height)
        let contributors = wrap.contributors.sort {
            
            if $0.current {
                return false
            } else if $1.current {
                return true
            }
            
            let activity0 = $0.activityForWrap(wrap)?.type
            let activity1 = $1.activityForWrap(wrap)?.type
            if activity0 != activity1 {
                if activity0 == .Live {
                    return true
                } else if activity1 == .Live {
                    return false
                } else if activity0 == .Video {
                    return true
                } else if activity1 == .Video {
                    return false
                } else if activity0 == .Photo {
                    return true
                } else if activity1 == .Photo {
                    return false
                } else if activity0 == .Typing {
                    return true
                } else if activity1 == .Typing {
                    return false
                }
            }
            
            if $0.isActive != $1.isActive {
                return $0.isActive
            }
            
            let noAvatar0 = ($0.avatar?.small?.isEmpty ?? true)
            let noAvatar1 = ($1.avatar?.small?.isEmpty ?? true)
            
            if noAvatar0 != noAvatar1 {
                return noAvatar1
            }
            
            return $0.name < $1.name
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
    
    private var viewController: UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let controller = viewController {
                let view = controller.view
                view.translatesAutoresizingMaskIntoConstraints = false
                view.frame = self.containerView.bounds
                containerView.addSubview(view)
                view.snp_makeConstraints(closure: { $0.edges.equalTo(containerView) })
                view.setNeedsLayout()
            }
        }
    }
    
    private func controllerNamed<T: WrapSegmentViewController>(name: String, badge: BadgeLabel?) -> T {
        let controller = storyboard?[name] as! T
        controller.preferredViewFrame = containerView.bounds
        controller.wrap = wrap
        controller.delegate = self
        addChildViewController(controller)
        controller.didMoveToParentViewController(self)
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
    
    @IBAction override func back(sender: UIButton) {
        navigationController?.popToRootViewControllerAnimated(false)
    }
}

extension WrapViewController: CaptureMediaViewControllerDelegate {
    
    func captureViewController(controller: CaptureMediaViewController, didFinishWithAssets assets: [MutableAsset]) {
        let wrap = controller.wrap ?? self.wrap
        if self.wrap != wrap {
            if let mainViewController = self.navigationController?.viewControllers.first, let wrapViewController = wrap?.viewController() {
                self.navigationController?.viewControllers = [mainViewController, wrapViewController]
            }
        }
        
        controller.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        
        Dispatch.mainQueue.async {
            FollowingViewController.followWrapIfNeeded(wrap) {
                Sound.play()
                wrap?.uploadAssets(assets)
            }
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
