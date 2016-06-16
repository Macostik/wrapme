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
    weak var wrap: Wrap!
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
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var friendsStreamView: StreamView!
    
    private var wrapNotifyReceiver: EntryNotifyReceiver<Wrap>?
    
    private var userNotifyReceiver: EntryNotifyReceiver<User>?
    
    private lazy var friendsDataSource: StreamDataSource<[AnyObject]> = StreamDataSource(streamView: self.friendsStreamView)
    
    @IBOutlet weak var moreFriendsLabel: UILabel!
    
    lazy var inboxViewController: InboxViewController = self.addController(InboxViewController())
    lazy var mediaViewController: MediaViewController = self.addController(MediaViewController())
    lazy var chatViewController: ChatViewController = self.addController(ChatViewController())
    
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
        guard let wrap = wrap where wrap.valid else { return }
        
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
        if wrap?.valid == true {
            updateWrapData()
            updateSegmentIfNeeded()
            updateMessageCouter()
        }
    }
    
    override func keyboardAdjustmentConstant(adjustment: KeyboardAdjustment, keyboard: Keyboard) -> CGFloat {
        let screenBounds = UIScreen.mainScreen().bounds
        if screenBounds.width == 320 && screenBounds.height == 480 {
            return -(segmentedControl.superview?.height ?? 0)
        } else {
            return 0
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
                    Toast.showMessageForUnavailableWrap(entry)
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
        chatSegmentButton.badge.value = wrap?.numberOfUnreadMessages ?? 0
    }
    
    private func updateInboxCounter() {
        inboxSegmentButton.badge.value = wrap?.numberOfUnreadInboxItems ?? 0
    }
    
    private var viewController: WrapSegmentViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let controller = viewController {
                controller.preferredViewFrame = containerView.bounds
                let view = controller.view
                view.translatesAutoresizingMaskIntoConstraints = false
                view.frame = self.containerView.bounds
                containerView.addSubview(view)
                view.snp_makeConstraints(closure: { $0.edges.equalTo(containerView) })
                view.setNeedsLayout()
            }
        }
    }
    
    private func controllerNamed<T: WrapSegmentViewController>(name: String) -> T {
        return addController(storyboard?[name] as! T)
    }
    
    private func addController<T: WrapSegmentViewController>(controller: T) -> T {
        controller.wrap = wrap
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
        guard let wrap = wrap else { return }
        let controller = ContributorsViewController(wrap: wrap)
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @IBAction override func back(sender: UIButton) {
        navigationController?.popToRootViewControllerAnimated(false)
    }
    
    @IBAction func addPhoto(sender: UIButton) {
        let captureViewController = CaptureViewController.captureMediaViewController(wrap)
        captureViewController.captureDelegate = self
        presentViewController(captureViewController, animated: false, completion: nil)
    }
}

extension WrapViewController: CaptureCandyViewControllerDelegate {
    
    func captureViewController(controller: CaptureCandyViewController, didFinishWithAssets assets: [MutableAsset]) {
        let wrap = controller.wrap ?? self.wrap
        if self.wrap != wrap {
            if let mainViewController = self.navigationController?.viewControllers.first, let wrapViewController = wrap?.createViewController() {
                self.navigationController?.viewControllers = [mainViewController, wrapViewController]
            }
        }
        
        controller.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        
        Dispatch.mainQueue.async {
            Sound.play()
            wrap?.uploadAssets(assets)
        }
    }
    
    func captureViewControllerDidCancel(controller: CaptureCandyViewController) {
        dismissViewControllerAnimated(false, completion: nil)
    }
}
