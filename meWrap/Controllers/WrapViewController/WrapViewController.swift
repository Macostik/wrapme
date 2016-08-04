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

class WrapBaseViewController: BaseViewController {
    let wrap: Wrap
    required init(wrap: Wrap) {
        self.wrap = wrap
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class WrapSegmentButton: Button {
    
    convenience init(icon: String, text: String) {
        self.init(frame: CGRect.zero)
        highlightedColor = Color.grayLightest
        exclusiveTouch = true
        iconLabel.text = icon
        textLabel.text = text
        badge.clipsToBounds = true
        badge.textAlignment = .Center
        badge.backgroundColor = Color.dangerRed
        badge.hidden = true
        selectionView.hidden = true
        selectionView.backgroundColor = Color.orange
        iconLabel.highlightedTextColor = Color.orange
        textLabel.highlightedTextColor = Color.orange
        let view = add(UIView()) { $0.center.equalTo(self) }
        view.userInteractionEnabled = false
        view.add(iconLabel) { $0.leading.top.bottom.equalTo(view) }
        view.add(textLabel) {
            $0.leading.equalTo(iconLabel.snp_trailing).offset(5)
            $0.trailing.centerY.equalTo(view)
        }
        add(selectionView) {
            $0.leading.trailing.bottom.equalTo(self)
            $0.height.equalTo(4)
        }
        add(badge) {
            $0.bottom.equalTo(view.snp_centerY).offset(-1)
            $0.leading.equalTo(iconLabel.snp_trailing).inset(10)
            $0.width.greaterThanOrEqualTo(badge.snp_height)
        }
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

final class WrapViewController: WrapBaseViewController {
    
    convenience init(wrap: Wrap, segment: WrapSegment) {
        self.init(wrap: wrap)
        self.segment = segment
    }
    
    var segment: WrapSegment = .Media {
        didSet {
            if isViewLoaded() && segment != oldValue {
                updateSegment()
            }
        }
    }
    
    private let nameLabel = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
    
    private let inboxSegmentButton = WrapSegmentButton(icon: "r", text: "inbox".ls)
    
    private let mediaSegmentButton = WrapSegmentButton(icon: "t", text: "media".ls)
    
    private let chatSegmentButton = WrapSegmentButton(icon: ";", text: "chat".ls)
    
    private let segmentedControl = SegmentedControl()
    private let topView = UIView()
    private let containerView = UIView()
    private let settingsButton = Button(type: .Custom)
    private lazy var videoCallButton: Button = Button(icon: "+", size: 26, textColor: UIColor.whiteColor())
    private lazy var audioCallButton: Button = Button(icon: "D", size: 26, textColor: UIColor.whiteColor())
    private lazy var friendsStreamView: StreamView = StreamView()
    private let friendsView = UIView()
    
    private lazy var friendAvatar: StatusUserAvatarView = StatusUserAvatarView(cornerRadius: 16)
    private lazy var friendName: Label = Label(preset: .Normal, weight: .Regular, textColor: .blackColor())
    private lazy var friendStatus: Label = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    
    private var wrapNotifyReceiver: EntryNotifyReceiver<Wrap>?
    
    private var userNotifyReceiver: EntryNotifyReceiver<User>?
    
    private lazy var friendsDataSource: StreamDataSource<[AnyObject]> = StreamDataSource(streamView: self.friendsStreamView)
    
    private lazy var moreFriendsLabel = Label(icon: "/", size: 24, textColor:Color.grayLighter)
    
    lazy var inboxViewController: InboxViewController = self.addController(InboxViewController(wrap: self.wrap))
    lazy var mediaViewController: MediaViewController = self.addController(MediaViewController(wrap: self.wrap))
    lazy var chatViewController: ChatViewController = self.addController(ChatViewController(wrap: self.wrap))
    
    override func loadView() {
        super.loadView()
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(containerView)
        view.addSubview(topView)
        
        let navigationBar = UIView()
        navigationBar.backgroundColor = Color.orange
        view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        let _backButton = navigationBar.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(navigationBar).offset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        
        let settingsTip = Label(preset: .XSmall, weight: .Light, textColor: UIColor(white: 1, alpha: 0.54))
        settingsTip.highlightedTextColor = Color.grayLighter
        settingsTip.text = "tap_for_settings".ls
        navigationBar.add(settingsTip) { (make) in
            make.centerX.equalTo(navigationBar)
            make.bottom.equalTo(navigationBar).offset(-3)
        }
        nameLabel.highlightedTextColor = Color.grayLighter
        
        settingsButton.exclusiveTouch = true
        settingsButton.addTarget(self, touchUpInside: #selector(self.settings(_:)))
        settingsButton.highlightings = [settingsTip, nameLabel]
        navigationBar.add(settingsButton) { (make) in
            make.center.height.equalTo(navigationBar)
            make.width.equalTo(settingsTip)
        }
        
        if wrap.p2p {
            audioCallButton.exclusiveTouch = true
            audioCallButton.addTarget(self, touchUpInside: #selector(self.audioCall(_:)))
            navigationBar.add(audioCallButton) { (make) in
                make.trailing.equalTo(navigationBar).offset(-12)
                make.centerY.equalTo(navigationBar).offset(10)
            }
            videoCallButton.exclusiveTouch = true
            videoCallButton.addTarget(self, touchUpInside: #selector(self.videoCall(_:)))
            navigationBar.add(videoCallButton) { (make) in
                make.trailing.equalTo(audioCallButton.snp_leading).offset(-12)
                make.centerY.equalTo(navigationBar).offset(10)
            }
        }
        navigationBar.add(nameLabel) { (make) in
            make.centerX.equalTo(navigationBar)
            make.bottom.equalTo(settingsTip.snp_top)
            make.leading.greaterThanOrEqualTo(_backButton.snp_trailing).offset(12)
            if wrap.p2p {
                make.trailing.lessThanOrEqualTo(videoCallButton.snp_leading).offset(-12)
            } else {
                make.trailing.lessThanOrEqualTo(navigationBar).offset(-12)
            }
        }
        
        self.navigationBar = navigationBar
        
        segmentedControl.backgroundColor = UIColor.whiteColor()
        
        containerView.snp_makeConstraints { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.top.equalTo(navigationBar.snp_bottom)
        }
        
        topView.add(friendsView) { (make) in
            make.leading.trailing.top.equalTo(topView)
        }
        topView.add(segmentedControl) { (make) in
            make.leading.trailing.bottom.equalTo(topView)
            make.top.equalTo(friendsView.snp_bottom)
            make.height.equalTo(50)
        }
        
        let friendsButton = Button(type: .Custom)
        friendsButton.backgroundColor = UIColor.whiteColor()
        friendsButton.normalColor = UIColor.whiteColor()
        friendsButton.exclusiveTouch = true
        friendsButton.highlightedColor = Color.grayLightest
        friendsButton.addTarget(self, touchUpInside: #selector(self.showFriends(_:)))
        friendsView.add(friendsButton) { (make) in
            make.edges.equalTo(friendsView)
        }
        
        if wrap.p2p {
            friendsView.add(friendAvatar, { (make) in
                make.size.equalTo(32)
                make.leading.equalTo(friendsView).offset(12)
                make.top.equalTo(friendsView).offset(9)
                make.bottom.equalTo(friendsView).offset(-9)
            })
            friendsView.add(friendName, { (make) in
                make.leading.equalTo(friendAvatar.snp_trailing).offset(12)
                make.trailing.lessThanOrEqualTo(friendsView).offset(-12)
                make.bottom.equalTo(friendAvatar.snp_centerY)
            })
            friendsView.add(friendStatus, { (make) in
                make.leading.equalTo(friendAvatar.snp_trailing).offset(12)
                make.trailing.lessThanOrEqualTo(friendsView).offset(-12)
                make.top.equalTo(friendAvatar.snp_centerY)
            })
        } else {
            friendsStreamView.scrollEnabled = false
            friendsStreamView.userInteractionEnabled = false
            friendsView.add(friendsStreamView, { (make) in
                make.edges.equalTo(friendsView)
                make.height.equalTo(50)
            })
            friendsStreamView.add(moreFriendsLabel) { (make) in
                make.width.equalTo(54)
                make.centerY.trailing.equalTo(friendsStreamView)
            }
        }
        
        defaultTopViewLayout()
        segmentedControl.add(SeparatorView(color: Color.grayLighter, contentMode: .Top)) { (make) in
            make.height.equalTo(1)
            make.leading.top.trailing.equalTo(segmentedControl)
        }
        segmentedControl.add(SeparatorView(color: Color.grayLighter)) { (make) in
            make.height.equalTo(1)
            make.leading.bottom.trailing.equalTo(segmentedControl)
        }
        segmentedControl.add(inboxSegmentButton) { (make) in
            make.leading.top.bottom.equalTo(segmentedControl)
        }
        segmentedControl.add(mediaSegmentButton) { (make) in
            make.top.bottom.equalTo(segmentedControl)
            make.leading.equalTo(inboxSegmentButton.snp_trailing)
            make.width.equalTo(inboxSegmentButton)
        }
        segmentedControl.add(chatSegmentButton) { (make) in
            make.trailing.top.bottom.equalTo(segmentedControl)
            make.leading.equalTo(mediaSegmentButton.snp_trailing)
            make.width.equalTo(mediaSegmentButton)
        }
        segmentedControl.setControls([inboxSegmentButton, mediaSegmentButton, chatSegmentButton])
        segmentedControl.addTarget(self, action: #selector(self.segmentChanged(_:)), forControlEvents: .ValueChanged)
        
        handleKeyboardIfNeeded()
        
        topContentInset = 100
    }
    
    private var topContentInset: CGFloat = 0 {
        didSet {
            guard topContentInset != oldValue else { return }
            inboxViewController.streamView.contentInset.top = topContentInset
            mediaViewController.streamView.contentInset.top = topContentInset
            chatViewController.streamView.contentInset.top = topContentInset
            inboxViewController.streamView.scrollIndicatorInsets.top = topContentInset
            mediaViewController.streamView.scrollIndicatorInsets.top = topContentInset
            chatViewController.streamView.scrollIndicatorInsets.top = topContentInset
        }
    }
    
    private lazy var missedCallLabel: Label = Label(preset: .Smaller, weight: .Regular, textColor: .whiteColor())
    private lazy var missedCallTimeLabel: Label = Label(preset: .XSmall, weight: .Regular, textColor: UIColor(white: 1, alpha: 0.54))
    private lazy var missedCallNumberLabel: Label = Label(preset: .Small, weight: .Regular, textColor: .whiteColor())
    private lazy var missedCallView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.dangerRed
        let dismissButton = Button(preset: .Small, weight: .Regular, textColor: UIColor(white: 1, alpha: 0.54))
        dismissButton.addTarget(self, touchUpInside: #selector(self.dismissMissedCallView(_:)))
        dismissButton.setTitle("dismiss".ls, forState: .Normal)
        view.add(dismissButton, { (make) in
            make.centerY.equalTo(view)
            make.trailing.equalTo(view).offset(-12)
        })
        view.add(self.missedCallNumberLabel, { (make) in
            make.centerY.equalTo(view)
            make.leading.equalTo(view).offset(12)
        })
        view.add(self.missedCallLabel, { (make) in
            make.bottom.equalTo(self.missedCallNumberLabel.snp_centerY)
            make.leading.equalTo(self.missedCallNumberLabel.snp_trailing)
            make.trailing.lessThanOrEqualTo(dismissButton.snp_leading).offset(-12)
        })
        view.add(self.missedCallTimeLabel, { (make) in
            make.top.equalTo(self.missedCallNumberLabel.snp_centerY)
            make.leading.equalTo(self.missedCallNumberLabel.snp_trailing)
            make.trailing.lessThanOrEqualTo(dismissButton.snp_leading).offset(-12)
        })
        let triangle = TriangleView()
        triangle.backgroundColor = view.backgroundColor
        triangle.contentMode = .Bottom
        view.add(triangle, { (make) in
            make.centerX.equalTo(view.snp_leading).offset(28)
            make.top.equalTo(view.snp_bottom)
            make.size.equalTo(CGSize(width: 16, height: 6))
        })
        return view
    }()
    
    func dismissMissedCallView(sender: Button) {
        wrap.missedCallDate = nil
        wrap.numberOfMissedCalls = 0
        hasMissedCall = false
    }
    
    private var hasMissedCall = false {
        didSet {
            guard hasMissedCall != oldValue else {
                if hasMissedCall {
                    updateMissedCallView()
                }
                return
            }
            if hasMissedCall {
                updateMissedCallView()
                friendAvatar.snp_updateConstraints(closure: { (make) in
                    make.top.equalTo(friendsView).offset(59)
                })
                friendsView.add(missedCallView, { (make) in
                    make.leading.top.trailing.equalTo(friendsView)
                    make.height.equalTo(50)
                })
            } else {
                missedCallView.removeFromSuperview()
                friendAvatar.snp_updateConstraints(closure: { (make) in
                    make.top.equalTo(friendsView).offset(9)
                })
            }
            topContentInset = hasMissedCall ? 150 : 100
        }
    }
    
    private func updateMissedCallView() {
        let numberOfMissedCalls = max(1, wrap.numberOfMissedCalls)
        missedCallNumberLabel.text = numberOfMissedCalls == 1 ? "" : "(\(numberOfMissedCalls))   "
        missedCallLabel.text = numberOfMissedCalls == 1 ? "missed_call".ls : "missed_calls".ls
        missedCallTimeLabel.text = wrap.missedCallDate?.timeAgoStringAtAMPM()
    }
    
    private func defaultTopViewLayout() {
        topView.snp_remakeConstraints(closure: { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(navigationBar!.snp_bottom)
        })
    }
    
    private func handleKeyboardIfNeeded() {
        let screenBounds = UIScreen.mainScreen().bounds
        if screenBounds.width == 320 && screenBounds.height == 480 {
            Keyboard.keyboard.handle(self, block: { [unowned self] (keyboard, willShow) in
                keyboard.performAnimation({ () in
                    self.setTopViewsHidden(willShow)
                })
            })
        }
    }
    
    func setTopViewsHidden(hidden: Bool) {
        if hidden {
            topView.snp_remakeConstraints { (make) in
                make.leading.trailing.equalTo(view)
                make.bottom.equalTo(navigationBar!)
            }
        } else {
            self.defaultTopViewLayout()
        }
        self.view.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        chatViewController.badge = chatSegmentButton.badge
        mediaViewController.addPhotoButton.addTarget(self, touchUpInside: #selector(self.addPhoto))
        super.viewDidLoad()
        
        addNotifyReceivers()
        
        if !wrap.p2p {
            friendsStreamView.layout = HorizontalStreamLayout()
            let friendMetrics = StreamMetrics<FriendView>(size: friendsStreamView.height)
            friendMetrics.modifyItem = { item in
                item.hidden = !(item.entry is User)
            }
            friendMetrics.prepareAppearing = { [weak self] item, view in
                view.wrap = self?.wrap
            }
            friendsDataSource.addMetrics(friendMetrics)
            let inviteeMetrics = StreamMetrics<InviteeView>(size: friendsStreamView.height)
            inviteeMetrics.modifyItem = { item in
                item.hidden = !(item.entry is Invitee)
            }
            friendsDataSource.addMetrics(inviteeMetrics)
        }
        
        guard case let wrap = wrap where wrap.valid else { return }
        
        segmentedControl.deselect()
        
        API.contributors(wrap).send({ [weak self] _ in
            self?.updateFriendsBar(wrap)
            }, failure: nil)
        
        if self.wrap.p2p {
            audioCallButton.active = Network.network.reachable
            videoCallButton.active = Network.network.reachable
        }
        
        Network.network.subscribe(self) { [unowned self] (value) in
            if self.wrap.p2p {
                self.audioCallButton.active = value
                self.videoCallButton.active = value
                self.updateFriendsBar(self.wrap)
            } else {
                self.friendsDataSource.reload()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        CandyCell.videoCandy = nil
        if wrap.valid == true {
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
        performWhenLoaded(mediaViewController, block: {
            $0.presentLiveBroadcast(broadcast)
        })
    }
    
    private func controllerForSegment(segment: WrapSegment) -> WrapBaseViewController {
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
                guard self?.view.window != nil else { return }
                if event == .NumberOfUnreadMessagesChanged {
                    if self?.segment != .Chat {
                        self?.updateMessageCouter()
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
                    Toast.showMessageForUnavailableWrap(entry)
                }
            }
            })
        
        userNotifyReceiver = EntryNotifyReceiver<User>().setup({ [weak self] (receiver) -> Void in
            receiver.shouldNotify = { user in
                return self?.wrap.contributors.contains(user) ?? false
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
        nameLabel.text = wrap.displayName
        updateFriendsBar(wrap)
    }
    
    private func updateFriendsBar(wrap: Wrap) {
        
        guard !wrap.p2p else {
            hasMissedCall = wrap.missedCallDate != nil && !CallView.isVisible
            if let friend = wrap.contributors.filter({ !$0.current }).first {
                friendStatus.text = friend.isOnline ? "online".ls : "offline".ls
                friendName.text = friend.name
                friendAvatar.user = friend
            }
            return
        }
        
        let maxFriendsCount = Int((Constants.screenWidth - moreFriendsLabel.width) / friendsStreamView.height)
        let invitees: [AnyObject] = Array(wrap.invitees)
        let contributors: [AnyObject] = wrap.contributors.sort {
            
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
                } else if activity0 == .Drawing {
                    return true
                } else if activity1 == .Drawing {
                    return false
                } else if activity0 == .Typing {
                    return true
                } else if activity1 == .Typing {
                    return false
                }
            }
            
            if $0.isOnline != $1.isOnline {
                return $0.isOnline
            }
            
            let noAvatar0 = ($0.avatar?.small?.isEmpty ?? true)
            let noAvatar1 = ($1.avatar?.small?.isEmpty ?? true)
            
            if noAvatar0 != noAvatar1 {
                return noAvatar1
            }
            
            return $0.name < $1.name
        }
        let friends = invitees + contributors
        moreFriendsLabel.hidden = friends.count <= maxFriendsCount
        friendsDataSource.items = Array(friends.prefix(maxFriendsCount))
    }
    
    private func updateMessageCouter() {
        chatSegmentButton.badge.value = wrap.numberOfUnreadMessages
    }
    
    private func updateInboxCounter() {
        inboxSegmentButton.badge.value = wrap.numberOfUnreadInboxItems
    }
    
    private var viewController: WrapBaseViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let controller = viewController {
                controller.preferredViewFrame = containerView.bounds
                let view = controller.view
                view.frame = self.containerView.bounds
                containerView.add(view) { $0.edges.equalTo(containerView) }
                view.setNeedsLayout()
            }
        }
    }
    
    private func controllerNamed<T: WrapBaseViewController>(name: String) -> T {
        return addController(storyboard?[name] as! T)
    }
    
    private func addController<T: WrapBaseViewController>(controller: T) -> T {
        addChildViewController(controller)
        controller.didMoveToParentViewController(self)
        return controller
    }
}

extension WrapViewController {
    
    @IBAction func segmentChanged(sender: SegmentedControl) {
        segment = WrapSegment(rawValue: sender.selectedSegment)!
    }
    
    @IBAction func showFriends(sender: AnyObject) {
        let controller = ContributorsViewController(wrap: wrap)
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @IBAction override func back(sender: UIButton) {
        navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func addPhoto() {
        let captureViewController = CaptureViewController.captureMediaViewController(wrap)
        captureViewController.captureDelegate = self
        presentViewController(captureViewController, animated: false, completion: nil)
    }
    
    @IBAction func settings(sender: UIButton) {
        let controller = WrapSettingsViewController(wrap: wrap)
        navigationController?.pushViewController(controller, animated: false)
    }
    
    private func call(isVideo: Bool) {
        wrap.missedCallDate = nil
        wrap.numberOfMissedCalls = 0
        hasMissedCall = false
        if let user = wrap.contributors.filter({ !$0.current }).first {
            CallCenter.center.call(user, isVideo: isVideo)
        }
    }
    
    @IBAction func audioCall(sender: UIButton) {
        call(false)
    }
    
    @IBAction func videoCall(sender: UIButton) {
        call(true)
    }
}

extension WrapViewController: CaptureCandyViewControllerDelegate {
    
    func captureViewController(controller: CaptureCandyViewController, didFinishWithAssets assets: [MutableAsset]) {
        let wrap = controller.wrap ?? self.wrap
        if self.wrap != wrap {
            if let mainViewController = self.navigationController?.viewControllers.first {
                self.navigationController?.viewControllers = [mainViewController, wrap.createViewController()]
            }
        }
        
        controller.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        
        Dispatch.mainQueue.async {
            Sound.play()
            wrap.uploadAssets(assets)
        }
    }
    
    func captureViewControllerDidCancel(controller: CaptureCandyViewController) {
        dismissViewControllerAnimated(false, completion: nil)
    }
}
