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

class LiveBroadcastEventView: UIView {
    
    convenience init(event: LiveBroadcast.Event) {
        self.init(frame: CGRect.zero)
        
        if event.kind == .Info {
            let textLabel = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
            textLabel.numberOfLines = 0
            backgroundColor = Color.orange
            addSubview(textLabel)
            textLabel.snp_makeConstraints(closure: {
                $0.top.bottom.equalTo(self).inset(7)
                $0.leading.trailing.equalTo(self).offset(12)
            })
            textLabel.text = event.text
        } else {
            backgroundColor = UIColor.whiteColor()
            let avatarView = ImageView(backgroundColor: UIColor.whiteColor(), placeholder: ImageView.Placeholder.gray)
            avatarView.cornerRadius = 20
            addSubview(avatarView)
            avatarView.snp_makeConstraints(closure: {
                $0.leading.top.equalTo(self).offset(12)
                $0.size.equalTo(40)
                $0.bottom.lessThanOrEqualTo(self).inset(12).priorityHigh()
            })
            
            let textLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayDarker)
            textLabel.numberOfLines = 0
            addSubview(textLabel)
            if event.kind == .Message {
                
                let nameLabel = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayDarker)
                addSubview(nameLabel)
                nameLabel.snp_makeConstraints(closure: {
                    $0.top.equalTo(avatarView.snp_top)
                    $0.leading.equalTo(avatarView.snp_trailing).offset(12)
                    $0.trailing.greaterThanOrEqualTo(self).offset(12)
                })
                
                textLabel.snp_makeConstraints(closure: {
                    $0.top.equalTo(nameLabel.snp_bottom)
                    $0.leading.equalTo(avatarView.snp_trailing).offset(12)
                    $0.trailing.equalTo(self).inset(12)
                    $0.bottom.equalTo(self).inset(12).priorityLow()
                })
                
                nameLabel.text = event.user?.name
                avatarView.url = event.user?.avatar?.small
                textLabel.text = event.text
            } else {
                textLabel.snp_makeConstraints(closure: {
                    $0.top.equalTo(avatarView)
                    $0.leading.equalTo(avatarView.snp_trailing).offset(12)
                    $0.trailing.equalTo(self).offset(12)
                    $0.bottom.equalTo(self).inset(12).priorityLow()
                })
                avatarView.url = event.user?.avatar?.small
                textLabel.text = event.text
            }
        }
    }
}

class LiveViewController: BaseViewController, ComposeBarDelegate {
    
    internal let joinsCountView = UIView()
    
    internal let joinsCountLabel = Label(preset: .Small, weight: .Regular, textColor: Color.orange)
    
    internal let wrapNameLabel = Label(preset: .Normal, weight: .Regular, textColor: UIColor.whiteColor())
    
    internal let titleLabel = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    
    var wrap: Wrap?
    
    internal let composeBar = ComposeBar()
    
    lazy var broadcast: LiveBroadcast = LiveBroadcast()
    
    lazy var chatSubscription: NotificationSubscription = {
        let chatSubscription = NotificationSubscription(name: "ch-\(self.broadcast.streamName)", isGroup: false, observePresence: true)
        chatSubscription.delegate = self
        NotificationCenter.defaultCenter.liveSubscription = chatSubscription
        return chatSubscription
    }()
    
    deinit {
        UIApplication.sharedApplication().idleTimerDisabled = false
    }
    
    internal func updateBroadcastInfo() {
        joinsCountLabel.text = "\(max(0, broadcast.viewers.count))"
        titleLabel.text = broadcast.displayTitle()
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.blackColor()
        let closeButton = Button(icon: "!", size: 17, textColor: UIColor.whiteColor())
        closeButton.cornerRadius = 18
        closeButton.clipsToBounds = true
        closeButton.borderColor = UIColor.whiteColor()
        closeButton.borderWidth = 2
        closeButton.addTarget(self, touchUpInside: #selector(self.close(_:)))
        closeButton.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        closeButton.normalColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        closeButton.highlightedColor = Color.grayLighter
        view.add(closeButton) { (make) in
            make.trailing.top.equalTo(view).inset(12)
            make.size.equalTo(36)
        }
        
        let wrapNameView = view.add(UIView()) { (make) in
            make.leading.top.equalTo(view).inset(12)
            make.trailing.lessThanOrEqualTo(closeButton.snp_leading).inset(-12)
        }
        wrapNameView.cornerRadius = 4
        wrapNameView.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        
        wrapNameView.add(wrapNameLabel) { (make) in
            make.edges.equalTo(wrapNameView).inset(6)
        }
        
        let titleView = view.add(UIView()) { (make) in
            make.leading.equalTo(view).inset(12)
            make.top.equalTo(wrapNameView.snp_bottom).inset(-12)
            make.trailing.lessThanOrEqualTo(closeButton.snp_leading).inset(-12)
        }
        titleView.cornerRadius = 4
        titleView.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        
        titleView.add(titleLabel) { (make) in
            make.edges.equalTo(titleView).inset(6)
        }
        
        composeBar.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        view.addSubview(composeBar)
        
        view.add(joinsCountView) { (make) in
            make.bottom.equalTo(composeBar.snp_top).inset(-12)
            make.trailing.equalTo(view).inset(12)
        }
        
        let joinsIcon = Label(icon: "&", size: 24, textColor: UIColor.whiteColor())
        joinsIcon.highlightedTextColor = Color.grayLighter
        
        joinsCountView.add(joinsIcon) { (make) in
            make.leading.top.bottom.equalTo(joinsCountView)
        }
        joinsCountLabel.highlightedTextColor = Color.grayLighter
        joinsCountLabel.backgroundColor = UIColor.whiteColor()
        joinsCountLabel.cornerRadius = 6
        joinsCountLabel.clipsToBounds = true
        joinsCountLabel.textAlignment = .Center
        joinsCountView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        joinsCountLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        joinsIcon.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        joinsCountLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        joinsCountView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        joinsIcon.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        joinsCountView.add(joinsCountLabel) { (make) in
            make.trailing.centerY.equalTo(joinsCountView)
            make.leading.equalTo(joinsIcon.snp_trailing)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(joinsCountLabel.snp_height)
        }
        let joinsButton = Button(type: .Custom)
        joinsButton.highlightings = [joinsCountLabel, joinsIcon]
        joinsButton.addTarget(self, touchUpInside: #selector(self.presentViewers(_:)))
        joinsCountView.add(joinsButton) { (make) in
            make.edges.equalTo(joinsCountView)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        wrapNameLabel.text = wrap?.name
        
        Wrap.notifier().addReceiver(self)
        
        composeBar.delegate = self
    }
    
    internal var eventViews = [LiveBroadcastEventView]()
    
    internal func insertEvent(event: LiveBroadcast.Event) {
        let eventView = LiveBroadcastEventView(event: event)
        
        view.add(eventView, { (make) in
            make.leading.equalTo(view).inset(12)
            make.trailing.equalTo(joinsCountView.snp_leading).inset(-12)
            if let latestEventView = eventViews.last {
                make.bottom.equalTo(latestEventView.snp_top).inset(-6)
            } else {
                make.bottom.equalTo(composeBar.snp_top).inset(-12)
            }
        })
        eventViews.append(eventView)
        eventView.alpha = 0
        UIView.animateWithDuration(0.5) {
            eventView.alpha = 1
        }
        if eventViews.count > 3 {
            eventViews.first?.removeFromSuperview()
            eventViews.removeFirst()
            if let first = eventViews.first {
                first.snp_remakeConstraints(closure: { (make) in
                    make.leading.equalTo(view).inset(12)
                    make.trailing.equalTo(joinsCountView.snp_leading).inset(-12)
                    make.bottom.equalTo(composeBar.snp_top).inset(-12)
                })
            }
        }
        
        Dispatch.mainQueue.after(4) { [weak eventView] () -> Void in
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                eventView?.alpha = 0
                }, completion: { _ in
                    eventView?.removeFromSuperview()
                    if let index = self.eventViews.indexOf({ $0 == eventView }) {
                        self.eventViews.removeAtIndex(index)
                    }
                    if let first = self.eventViews.first {
                        first.snp_remakeConstraints(closure: { (make) in
                            make.leading.equalTo(self.view).inset(12)
                            make.trailing.equalTo(self.joinsCountView.snp_leading).inset(-12)
                            make.bottom.equalTo(self.composeBar.snp_top).inset(-12)
                        })
                    }
                    UIView.animateWithDuration(0.5) {
                        self.view.layoutIfNeeded()
                    }
            })
        }
    }
    
    internal func close() {
        navigationController?.popViewControllerAnimated(false)
    }
    
    @IBAction func close(sender: UIButton) {
        close()
    }
    
    private weak var viewersController: LiveBroadcastViewersViewController?
    
    @IBAction func presentViewers(sender: AnyObject) {
        let controller = LiveBroadcastViewersViewController(broadcast: broadcast)
        addContainedViewController(controller, animated: false)
        viewersController = controller
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.All]
    }
    
    override func shouldAutorotate() -> Bool {
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
        guard let message = message.data.message as? [String : AnyObject],
            let user = User.entry(message["userUid"] as? String),
            let text = message["content"] as? String else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            let event = LiveBroadcast.Event(kind: .Message)
            event.user = user
            event.text = text
            self?.insertEvent(event)
            }, failure: nil)
    }
    
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult) {
        guard let uuid = event.data.presence.uuid where uuid != User.uuid() else { return }
        guard let user = PubNub.userFromUUID(uuid) else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            guard let controller = self else { return }
            let broadcast = controller.broadcast
            switch event.data.presenceEvent {
            case "join":
                let event = LiveBroadcast.Event(kind: .Join)
                event.text = "\(user.name ?? "") \("joined".ls)"
                event.user = user
                self?.insertEvent(event)
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
