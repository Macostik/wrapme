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
            RunQueue.fetchQueue.run({ (finish) -> Void in
                self.alpha = 0.0
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.alpha = 1.0
                    finish()
                })
            })
            
            if event.kind == .Message {
                nameLabel?.text = event.user?.name
            }
            avatarView?.url = event.user?.avatar?.small
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
    
    private let loader = IndexedStreamLoader(identifier: "LiveBroadcastEventViews", index: 0)
    
    private func metricsForEventOfKind(kind: LiveBroadcast.Event.Kind, minSize: CGFloat) -> StreamMetrics {
        let metrics = StreamMetrics(loader: loader.loader(kind.rawValue))
        return metrics.change { [weak self] (metrics) -> Void in
            metrics.sizeAt = { self?.chatStreamView.dynamicSizeForMetrics(metrics, item: $0, minSize: minSize) ?? minSize }
            metrics.hiddenAt = { ($0.entry as! LiveBroadcast.Event).kind != kind }
            metrics.insetsAt = { CGRect(x: 0, y: $0.position.index == 0 ? 0 : 6, width: 0, height: 0) }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIView.performWithoutAnimation { UIViewController.attemptRotationToDeviceOrientation() }
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        let streamView = chatStreamView
        
        streamView.layer.geometryFlipped = true
        
        chatDataSource = StreamDataSource(streamView: streamView)
        chatDataSource.addMetrics(metricsForEventOfKind(.Message, minSize: 64))
        chatDataSource.addMetrics(metricsForEventOfKind(.Join, minSize: 64))
        chatDataSource.addMetrics(metricsForEventOfKind(.Info, minSize: 32))
        
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
            let event = LiveBroadcast.Event(kind: .Message)
            event.user = user
            event.text = text
            self?.broadcast.insert(event)
            self?.chatDataSource.items = self?.broadcast.events
            }, failure: nil)
    }
    
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult) {
        guard let uuid = event.data?.presence?.uuid else { return }
        guard let user = PubNub.userFromUUID(uuid) where user != broadcast.broadcaster else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            guard let controller = self else { return }
            let broadcast = controller.broadcast
            switch event.data.presenceEvent {
            case "join":
                let event = LiveBroadcast.Event(kind: .Join)
                event.text = "\(user.name ?? "") \("joined".ls)"
                event.user = user
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
