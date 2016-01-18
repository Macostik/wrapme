//
//  LiveBroadcastViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import PubNub
import AVFoundation

class LiveBroadcastEventView: StreamReusableView {
    
    @IBOutlet weak var avatarView: ImageView?
    
    @IBOutlet weak var nameLabel: UILabel?
    
    @IBOutlet weak var textLabel: UILabel!
    
    override func setup(entry: AnyObject!) {
        if let event = entry as? LiveBroadcast.Event {
            if event.type == .Message {
                avatarView?.url = event.user?.avatar?.small
                nameLabel?.text = event.user?.name
            }
            textLabel.text = event.text
            hidden = false
            event.disappearingBlock = { [weak self] () -> Void in
                self?.hidden = true
                self?.addAnimation(CATransition.transition(kCATransitionFade, duration: 1))
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.geometryFlipped = true
    }
}

class LiveViewController: WLBaseViewController {
        
    @IBOutlet weak var joinsCountView: UIView!
    
    @IBOutlet weak var joinsCountLabel: UILabel!
    
    @IBOutlet weak var chatStreamView: StreamView!
        
    var chatDataSource: StreamDataSource!
    
    @IBOutlet weak var wrapNameLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var wrap: Wrap?
    
    @IBOutlet weak var composeBar: WLComposeBar!
    
    lazy var broadcast: LiveBroadcast = LiveBroadcast()
    
    var chatSubscription: NotificationSubscription?
    
    var allowAutorotate = true
    
    deinit {
        UIApplication.sharedApplication().idleTimerDisabled = false
    }
    
    internal func updateBroadcastInfo() {
        joinsCountLabel.text = "\(max(0, broadcast.viewers.count))"
        titleLabel?.text = broadcast.displayTitle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIView.performWithoutAnimation { UIViewController.attemptRotationToDeviceOrientation() }
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        chatStreamView.layer.geometryFlipped = true
        
        chatDataSource = StreamDataSource(streamView: chatStreamView)
        chatDataSource.addMetrics(StreamMetrics(loader: IndexedStreamLoader(identifier: "LiveBroadcastEventViews", index: 0))).change { (metrics) -> Void in
            metrics.sizeAt = { [weak self] item -> CGFloat in
                return self?.chatStreamView?.dynamicSizeForMetrics(metrics, item: item, minSize: 72) ?? 72
            }
            metrics.hiddenAt = { item -> Bool in
                let event = item.entry as? LiveBroadcast.Event
                return event?.type != .Message
            }
            metrics.insetsAt = { CGRect(x: 0, y: $0.position.index == 0 ? 0 : 6, width: 0, height: 0) }
        }
        chatDataSource.addMetrics(StreamMetrics(loader: IndexedStreamLoader(identifier: "LiveBroadcastEventViews", index: 1))).change { (metrics) -> Void in
            metrics.sizeAt = { [weak self] item -> CGFloat in
                return self?.chatStreamView?.dynamicSizeForMetrics(metrics, item: item, minSize: 32) ?? 32
            }
            metrics.hiddenAt = { item -> Bool in
                let event = item.entry as? LiveBroadcast.Event
                return event?.type != .Info
            }
            metrics.insetsAt = { CGRect(x: 0, y: $0.position.index == 0 ? 0 : 6, width: 0, height: 0) }
        }
        
        wrapNameLabel?.text = wrap?.name
        
        Wrap.notifier().addReceiver(self)
    }
    
    internal func subscribe(broadcast: LiveBroadcast) {
        let chatSubscription = NotificationSubscription(name: "ch-\(broadcast.streamName)", isGroup: false, observePresence: true)
        chatSubscription.delegate = self
        chatSubscription.subscribe()
        self.chatSubscription = chatSubscription
    }
    
    internal func close() {
        navigationController?.popViewControllerAnimated(false)
    }
    
    @IBAction func close(sender: UIButton) {
        close()
    }
    
    private weak var viewersController: LiveBroadcastViewersViewController?
    
    @IBAction func presentViewers(sender: AnyObject) {
        if let controller = storyboard?["broadcastViewers"] as? LiveBroadcastViewersViewController {
            controller.broadcast = broadcast
            presentViewController(controller, animated: false, completion: nil)
            viewersController = controller
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.All]
    }
    
    override func shouldAutorotate() -> Bool {
        return allowAutorotate
    }
}

extension LiveViewController: WLComposeBarDelegate {
    
    func composeBarDidShouldResignOnFinish(composeBar: WLComposeBar!) -> Bool {
        return true
    }
}

extension LiveViewController: EntryNotifying {
    
    internal func wrapLiveBroadcastsUpdated() { }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        guard event == .LiveBroadcastsChanged else { return }
        wrapLiveBroadcastsUpdated()
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
}

extension LiveViewController: NotificationSubscriptionDelegate {
    func notificationSubscription(subscription: NotificationSubscription, didReceiveMessage message: PNMessageResult) {
        guard let message = message.data?.message as? [String : AnyObject],
            let user = User.entry(message["userUid"] as? String),
            let text = message["content"] as? String else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            let event = LiveBroadcast.Event(type: .Message)
            event.user = user
            event.text = text
            self?.broadcast.insert(event)
            self?.chatDataSource.items = self?.broadcast.events
            }, failure: nil)
    }
    
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult) {
        guard let uuid = event.data?.presence?.uuid where uuid != User.channelName() else { return }
        guard let user = PubNub.userFromUUID(uuid) where !user.current && user != broadcast.broadcaster else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            guard let controller = self else { return }
            let broadcast = controller.broadcast
            switch event.data.presenceEvent {
            case "join":
                let event = LiveBroadcast.Event(type: .Info)
                event.text = "\(user.name ?? "") \("joined".ls)"
                broadcast.insert(event)
                controller.chatDataSource.items = broadcast.events
                broadcast.viewers.insert(user)
                break
            case "leave", "timeout":
                broadcast.viewers.remove(user)
                break
            default: break
            }
            controller.updateBroadcastInfo()
            controller.viewersController?.update()
            }, failure: nil)
    }
}
