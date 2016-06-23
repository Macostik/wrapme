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
    private let containerView = UIView()
    private let settingsButton = Button(icon: "0", size: 26, textColor: UIColor.whiteColor())
    private let friendsStreamView = StreamView()
    
    private var wrapNotifyReceiver: EntryNotifyReceiver<Wrap>?
    
    private var userNotifyReceiver: EntryNotifyReceiver<User>?
    
    private lazy var friendsDataSource: StreamDataSource<[AnyObject]> = StreamDataSource(streamView: self.friendsStreamView)
    
    private let moreFriendsLabel = Label(icon: "/", size: 24, textColor:Color.grayLighter)
    
    lazy var inboxViewController: InboxViewController = self.addController(InboxViewController(wrap: self.wrap))
    lazy var mediaViewController: MediaViewController = self.addController(MediaViewController(wrap: self.wrap))
    lazy var chatViewController: ChatViewController = self.addController(ChatViewController(wrap: self.wrap))
    
    override func loadView() {
        super.loadView()
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = UIColor.whiteColor()
        let navigationBar = UIView()
        navigationBar.backgroundColor = Color.orange
        segmentedControl.backgroundColor = UIColor.whiteColor()
        view.addSubview(containerView)
        view.addSubview(friendsStreamView)
        view.addSubview(segmentedControl)
        view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        let _backButton = navigationBar.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(navigationBar).offset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        settingsButton.addTarget(self, touchUpInside: #selector(self.settings(_:)))
        navigationBar.add(settingsButton) { (make) in
            make.trailing.equalTo(navigationBar).offset(-12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        navigationBar.add(nameLabel) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
            make.leading.greaterThanOrEqualTo(_backButton.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(settingsButton.snp_leading).offset(-12)
        }
        self.navigationBar = navigationBar
        containerView.snp_makeConstraints { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.top.equalTo(navigationBar.snp_bottom)
        }
        friendsStreamView.scrollEnabled = false
        friendsStreamView.userInteractionEnabled = false
        friendsStreamView.add(moreFriendsLabel) { (make) in
            make.width.equalTo(54)
            make.centerY.trailing.equalTo(friendsStreamView)
        }
        let friendsButton = Button(type: .Custom)
        friendsButton.backgroundColor = UIColor.whiteColor()
        friendsButton.normalColor = UIColor.whiteColor()
        friendsButton.exclusiveTouch = true
        friendsButton.highlightedColor = Color.grayLightest
        friendsButton.addTarget(self, touchUpInside: #selector(self.showFriends(_:)))
        view.insertSubview(friendsButton, belowSubview: friendsStreamView)
        friendsButton.snp_makeConstraints { (make) in
            make.size.equalTo(friendsStreamView)
            make.center.equalTo(friendsStreamView)
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
    }
    
    private func defaultTopViewLayout() {
        self.segmentedControl.snp_remakeConstraints { (make) in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(self.friendsStreamView.snp_bottom)
            make.height.equalTo(50)
        }
        self.friendsStreamView.snp_remakeConstraints(closure: { (make) in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(navigationBar!.snp_bottom)
            make.height.equalTo(50)
        })
    }
    
    private func handleKeyboardIfNeeded() {
        let screenBounds = UIScreen.mainScreen().bounds
        if screenBounds.width == 320 && screenBounds.height == 480 {
            Keyboard.keyboard.handle(self, willShow: { [unowned self] (keyboard) in
                keyboard.performAnimation({ () in
                    self.setTopViewsHidden(true)
                })
            }) { [unowned self] (keyboard) in
                keyboard.performAnimation({ () in
                    self.setTopViewsHidden(false)
                })
            }
        }
    }
    
    func setTopViewsHidden(hidden: Bool) {
        if hidden {
            self.friendsStreamView.snp_remakeConstraints(closure: { (make) in
                make.leading.trailing.equalTo(self.view)
                make.height.equalTo(50)
                
            })
            self.segmentedControl.snp_remakeConstraints { (make) in
                make.leading.trailing.equalTo(self.view)
                make.top.equalTo(self.friendsStreamView.snp_bottom)
                make.height.equalTo(50)
                make.bottom.equalTo(self.navigationBar!)
            }
        } else {
            self.defaultTopViewLayout()
        }
        self.view.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        chatViewController.badge = chatSegmentButton.badge
        mediaViewController.addPhotoButton.addTarget(self, touchUpInside: #selector(self.addPhoto(_:)))
        super.viewDidLoad()
        
        addNotifyReceivers()
        
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
        guard case let wrap = wrap where wrap.valid else { return }
        
        segmentedControl.deselect()
        
        settingsButton.exclusiveTouch = true
        
        API.contributors(wrap).send({ [weak self] _ in
            self?.updateFriendsBar(wrap)
            }, failure: nil)
        
        Network.network.subscribe(self) { [unowned self] (value) in
            self.friendsDataSource.reload()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
                if event == .NumberOfUnreadMessagesChanged {
                    if self?.segment != .Chat {
                        self?.chatSegmentButton.badge.value = self?.wrap.numberOfUnreadMessages ?? 0
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
        nameLabel.text = wrap.name
        updateFriendsBar(wrap)
    }
    
    private func updateFriendsBar(wrap: Wrap) {
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
        chatSegmentButton.badge.value = wrap.numberOfUnreadMessages ?? 0
    }
    
    private func updateInboxCounter() {
        inboxSegmentButton.badge.value = wrap.numberOfUnreadInboxItems ?? 0
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
    
    @IBAction func addPhoto(sender: UIButton) {
        VideoPlayer.pauseAll.notify()
        let captureViewController = CaptureViewController.captureMediaViewController(wrap)
        captureViewController.captureDelegate = self
        presentViewController(captureViewController, animated: false, completion: nil)
    }
    
    @IBAction func settings(sender: UIButton) {
        let controller = UIStoryboard.main["wrapSettings"] as! WrapSettingsViewController
        controller.wrap = wrap
        navigationController?.pushViewController(controller, animated: false)
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
        
        controller.presentingViewController?.dismissViewControllerAnimated(false, completion: {
            VideoPlayer.resumeAll.notify()
        })
        
        Dispatch.mainQueue.async {
            Sound.play()
            wrap.uploadAssets(assets)
        }
    }
    
    func captureViewControllerDidCancel(controller: CaptureCandyViewController) {
        dismissViewControllerAnimated(false, completion: {
            VideoPlayer.resumeAll.notify()
        })
    }
}
