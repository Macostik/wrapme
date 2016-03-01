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
    
    static let queue: RunQueue = RunQueue(limit: 1)
    
    override func setup(entry: AnyObject?) {
        if let event = entry as? LiveBroadcast.Event {
            LiveBroadcastEventView.queue.run({ (finish) -> Void in
                self.alpha = 0.0
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.alpha = 1.0
                    finish()
                })
            })
            hidden = false
            event.disappearingBlock = { [weak self] () -> Void in
                self?.hidden = true
                self?.addAnimation(CATransition.transition(kCATransitionFade, duration: 1))
            }
        }
    }
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        layer.geometryFlipped = true
    }
}

class LiveBroadcastEventWithAvatarView: LiveBroadcastEventView {
    
    internal var avatarView = ImageView(backgroundColor: UIColor.whiteColor())
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        backgroundColor = UIColor.whiteColor()
        avatarView.cornerRadius = 20
        avatarView.defaultBackgroundColor = Color.grayLighter
        avatarView.defaultIconColor = UIColor.whiteColor()
        avatarView.defaultIconText = "&"
        addSubview(avatarView)
        avatarView.snp_makeConstraints(closure: {
            $0.leading.top.equalTo(self).offset(12)
            $0.size.equalTo(40)
        })
    }
}

class LiveBroadcastMessageEventView: LiveBroadcastEventWithAvatarView {
    
    private var nameLabel = Label(preset: FontPreset.Smaller, weight: UIFontWeightRegular, textColor: Color.grayDarker)
    
    private var textLabel = Label(preset: FontPreset.Normal, weight: UIFontWeightRegular, textColor: Color.grayDarker)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        textLabel.numberOfLines = 0
        addSubview(nameLabel)
        addSubview(textLabel)
        
        nameLabel.snp_makeConstraints(closure: {
            $0.top.equalTo(avatarView.snp_top)
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.trailing.greaterThanOrEqualTo(self).offset(12)
        })
        
        textLabel.snp_makeConstraints(closure: {
            $0.top.equalTo(nameLabel.snp_bottom)
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.trailing.equalTo(self).inset(12)
            $0.bottom.equalTo(self).inset(12)
        })
    }
    
    override func setup(entry: AnyObject?) {
        super.setup(entry)
        if let event = entry as? LiveBroadcast.Event {
            nameLabel.text = event.user?.name
            avatarView.url = event.user?.avatar?.small
            textLabel.text = event.text
        }
    }
}

class LiveBroadcastJoinEventView: LiveBroadcastEventWithAvatarView {
    
    private var textLabel = Label(preset: FontPreset.Normal, weight: UIFontWeightRegular, textColor: Color.grayDarker)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        textLabel.numberOfLines = 0
        addSubview(textLabel)
        textLabel.snp_makeConstraints(closure: {
            $0.top.equalTo(avatarView)
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.trailing.equalTo(self).offset(12)
            $0.bottom.equalTo(self).inset(12)
        })
    }
    
    override func setup(entry: AnyObject?) {
        super.setup(entry)
        if let event = entry as? LiveBroadcast.Event {
            avatarView.url = event.user?.avatar?.small
            textLabel.text = event.text
        }
    }
}

class LiveBroadcastInfoEventView: LiveBroadcastEventView {
    
    private var textLabel = Label(preset: FontPreset.Small, weight: UIFontWeightRegular, textColor: UIColor.whiteColor())
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        super.layoutWithMetrics(metrics)
        textLabel.numberOfLines = 0
        backgroundColor = Color.orange
        addSubview(textLabel)
        textLabel.snp_makeConstraints(closure: {
            $0.top.bottom.equalTo(self).inset(7)
            $0.leading.trailing.equalTo(self).offset(12)
        })
    }
    
    override func setup(entry: AnyObject?) {
        super.setup(entry)
        if let event = entry as? LiveBroadcast.Event {
            textLabel.text = event.text
        }
    }
}

class LiveViewController: BaseViewController {
        
    @IBOutlet weak var joinsCountView: UIView!
    
    @IBOutlet weak var joinsCountLabel: UILabel!
    
    @IBOutlet weak var chatStreamView: StreamView!
        
    var chatDataSource: StreamDataSource!
    
    @IBOutlet weak var wrapNameLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var wrap: Wrap?
    
    @IBOutlet weak var composeBar: ComposeBar!
    
    lazy var broadcast: LiveBroadcast = LiveBroadcast()
    
    lazy var chatSubscription: NotificationSubscription = {
        let chatSubscription = NotificationSubscription(name: "ch-\(self.broadcast.streamName)", isGroup: false, observePresence: true)
        chatSubscription.delegate = self
        return chatSubscription
    }()
    
    var allowAutorotate = true
    
    deinit {
        UIApplication.sharedApplication().idleTimerDisabled = false
    }
    
    internal func updateBroadcastInfo() {
        joinsCountLabel.text = "\(max(0, broadcast.viewers.count))"
        titleLabel?.text = broadcast.displayTitle()
    }
    
    private func metricsForType<T: LiveBroadcastEventView>(type: T.Type, kind: LiveBroadcast.Event.Kind, minSize: CGFloat) -> StreamMetrics {
        let metrics = StreamMetrics(loader: LayoutStreamLoader<T>())
        metrics.modifyItem = { [weak self] item in
            item.size = self?.chatStreamView.dynamicSizeForMetrics(metrics, item: item, minSize: minSize) ?? minSize
            item.hidden = (item.entry as! LiveBroadcast.Event).kind != kind
            item.insets.origin.y = item.position.index == 0 ? 0 : 6
        }
        return metrics
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIView.performWithoutAnimation { UIViewController.attemptRotationToDeviceOrientation() }
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        let streamView = chatStreamView
        
        streamView.layer.geometryFlipped = true
        
        chatDataSource = StreamDataSource(streamView: streamView)
        
        chatDataSource.addMetrics(metricsForType(LiveBroadcastMessageEventView.self, kind: .Message, minSize: 64))
        chatDataSource.addMetrics(metricsForType(LiveBroadcastJoinEventView.self, kind: .Join, minSize: 64))
        chatDataSource.addMetrics(metricsForType(LiveBroadcastInfoEventView.self, kind: .Info, minSize: 32))
        
        wrapNameLabel?.text = wrap?.name
        
        Wrap.notifier().addReceiver(self)
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
            addContainedViewController(controller, animated: false)
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
