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
                textLabel.text = event.text
                avatarView?.url = event.user?.avatar?.small
                nameLabel?.text = event.user?.name
            } else {
                textLabel.text = "\(event.user?.name ?? "") \("joined".ls)"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.geometryFlipped = true
    }
}

class LiveBroadcastViewController: WLBaseViewController {
    
    @IBOutlet var layoutPrioritizer: LayoutPrioritizer!
    
    @IBOutlet weak var joinsCountView: UIView!
    
    @IBOutlet weak var joinsCountLabel: UILabel!
    
    @IBOutlet weak var chatStreamView: StreamView!
    
    var chatDataSource: StreamDataSource!
    
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    
    weak var playerLayer: AVPlayerLayer?
    
    var playerItem: AVPlayerItem?
    
    @IBOutlet weak var wrapNameLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    private var connectionID: Int32?
    
    var wrap: Wrap?
    
    @IBOutlet weak var composeBar: WLComposeBar!
    
    @IBOutlet weak var startButton: UIButton!
    
    var isBroadcasting = false
    
    var broadcast: LiveBroadcast?
    
    var chatSubscription: NotificationSubscription?
    
    var userState = [NSObject:AnyObject]() {
        didSet {
            if let channel = wrap?.uid, let uuid = User.currentUser?.uid {
                userState["userUid"] = uuid
                WLNotificationCenter.defaultCenter().userSubscription.changeState(userState, channel: channel)
            }
        }
    }
    
    deinit {
        UIApplication.sharedApplication().idleTimerDisabled = false
        guard let item = playerItem else {
            return
        }
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
    
    private func updateBroadcastInfo() {
        if let broadcast = broadcast {
            joinsCountLabel.text = "\(broadcast.numberOfViewers)"
            titleLabel?.text = broadcast.title
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        chatStreamView.layer.geometryFlipped = true
        
        chatDataSource = StreamDataSource(streamView: chatStreamView)
        chatDataSource.addMetrics(StreamMetrics(loader: IndexedStreamLoader(identifier: "LiveBroadcastEventViews", index: 0))).change { (metrics) -> Void in
            metrics.sizeAt = { [weak self] (position, metrics) -> CGFloat in
                let event = self?.broadcast?.events[position.index]
                if let streamView = self?.chatStreamView, let view = (metrics as StreamMetrics).loadView() {
                    view.width = streamView.width
                    view.entry = event
                    let size = view.contentView!.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                    return max(size.height, 72)
                } else {
                    return 72
                }
            }
            metrics.hiddenAt = { [weak self] (position, _) -> Bool in
                let event = self?.broadcast?.events[position.index]
                return event?.type != .Message
            }
            metrics.insetsAt = { (position, _) -> CGRect in
                return CGRect(x: 0, y: position.index == 0 ? 0 : 6, width: 0, height: 0)
            }
        }
        chatDataSource.addMetrics(StreamMetrics(loader: IndexedStreamLoader(identifier: "LiveBroadcastEventViews", index: 1))).change { (metrics) -> Void in
            metrics.size = 32
            metrics.hiddenAt = { [weak self] (position, _) -> Bool in
                let event = self?.broadcast?.events[position.index]
                return event?.type != .Join
            }
            metrics.insetsAt = { (position, _) -> CGRect in
                return CGRect(x: 0, y: position.index == 0 ? 0 : 6, width: 0, height: 0)
            }
        }
        
        wrapNameLabel?.text = wrap?.name
        
        if let broadcast = broadcast {
            initializeViewing(broadcast)
        } else {
            initializeBroadcasting()
        }
        Wrap.notifier().addReceiver(self)
    }
    
    private func initializeViewing(broadcast: LiveBroadcast) {
        isBroadcasting = false
        
        layoutPrioritizer.defaultState = false
        startButton.hidden = true
        
        if let url = broadcast.url.URL {
            let layer = AVPlayerLayer()
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill
            layer.frame = view.bounds
            view.layer.insertSublayer(layer, atIndex: 0)
            playerLayer = layer
            
            let playerItem = AVPlayerItem(URL: url)
            playerItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
            playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
            let player = AVPlayer(playerItem: playerItem)
            layer.player = player
            self.playerItem = playerItem
            
            subscribe(broadcast)
            
            updateBroadcastInfo()
            
            if let channel = wrap?.uid {
                PubNub.sharedInstance.stateForUUID(broadcast.channel, onChannel: channel, withCompletion: { [weak self] (result, status) -> Void in
                    if let state = result?.data?.state, let numberOfViewers = state["numberOfViewers"] as? Int {
                        if let broadcast = self?.broadcast {
                            broadcast.numberOfViewers = numberOfViewers
                            self?.updateBroadcastInfo()
                        }
                    }
                })
            }
        }
    }
    
    private func subscribe(broadcast: LiveBroadcast) {
        let chatSubscription = NotificationSubscription(name: broadcast.channel, isGroup: false, observePresence: true)
        chatSubscription.delegate = self
        self.chatSubscription = chatSubscription
    }
    
    private func initializeBroadcasting() {
        chatStreamView.hidden = true
        joinsCountView.hidden = true
        isBroadcasting = true
        titleLabel?.superview?.hidden = true
        guard let cameraInfo = CameraInfo.getCameraList().first as? CameraInfo else {
            return
        }
        
        let videoConfig = VideoConfig()
        videoConfig.videoSize = (cameraInfo.videoSizes?[1] as! NSValue).CGSizeValue()
        videoConfig.bitrate = 2000000
        videoConfig.fps = 30
        videoConfig.keyFrameInterval = 2
        videoConfig.profileLevel = VideoConfig.getSupportedProfiles().first as! String
        
        let audioConfig = AudioConfig()
        audioConfig.sampleRate = (AudioConfig.getSupportedSampleRates().first as! NSNumber).floatValue
        let streamer = Streamer.instance() as! Streamer
        var orientation = AVCaptureVideoOrientation.Portrait
        switch WLDeviceManager.defaultManager().orientation {
        case .PortraitUpsideDown:
            orientation = .PortraitUpsideDown
            break
        case .LandscapeLeft:
            orientation = .LandscapeLeft
            break
        case .LandscapeRight:
            orientation = .LandscapeRight
            break
        default: break
        }
        let layer = streamer.startVideoCaptureWithCamera(cameraInfo.cameraID, orientation: orientation, config: videoConfig, listener: self)
        layer.frame = view.bounds
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.insertSublayer(layer, atIndex: 0)
        streamer.startAudioCaptureWithConfig(audioConfig, listener: self)
        previewLayer = layer
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let player = playerLayer?.player, let item = playerItem else {
            return
        }
        if keyPath == "status" {
            if item.status == .ReadyToPlay {
                player.play()
            }
        } else if keyPath == "playbackLikelyToKeepUp" {
            if item.playbackLikelyToKeepUp == true {
                player.play()
            }
        }
    }
    
    func start() throws {
        
        guard let wrap = wrap else { throw NSError(message: "no wrap") }
        guard let userUID = User.currentUser?.uid else { throw NSError(message: "no user_uid") }
        guard let deviceUID = Authorization.currentAuthorization.deviceUID else { throw NSError(message: "no device_uid") }
        
        titleLabel?.text = composeBar.text
        titleLabel?.superview?.hidden = false
        
        let streamer = Streamer.instance() as! Streamer
        let channel = "\(userUID)-\(deviceUID)"
        
        let broadcast = LiveBroadcast()
        broadcast.title = composeBar.text
        broadcast.broadcaster = User.currentUser
        broadcast.url = "http://live.mewrap.me:1935/live/\(channel)/playlist.m3u8"
        broadcast.channel = channel
        broadcast.wrap = wrap
        self.broadcast = wrap.addBroadcast(broadcast)
        
        userState = [
            "title" : broadcast.title,
            "viewURL" : broadcast.url,
            "chatChannel" : channel,
            "numberOfViewers" : broadcast.numberOfViewers
        ]
        
        let uri = "rtsp://live.mewrap.me:1935/live/\(channel)"
        connectionID = streamer.createConnectionWithListener(self, uri: uri, mode: 0)
        
        subscribe(broadcast)
        updateBroadcastInfo()
    }
    
    func stop() {
        if let broadcast = broadcast {
            
            userState = [
                "chatChannel":broadcast.channel
            ]
            
            wrap?.removeBroadcast(broadcast)
        }
        
        if let connectionID = connectionID {
            self.connectionID = nil
            let streamer = Streamer.instance() as! Streamer
            streamer.releaseConnectionId(connectionID)
        }
    }
    
    @IBAction func startBroadcast(sender: UIButton) {
        if composeBar.text.isEmpty {
            composeBar.becomeFirstResponder()
        } else {
            if composeBar.isFirstResponder() {
                composeBar.resignFirstResponder()
            }
            do {
                try start()
            } catch {
            }
            joinsCountView.hidden = false
            chatStreamView.hidden = false
            sender.hidden = true
            composeBar.hidden = true
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "focusing:"))
            view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "zooming:"))
        }
    }
    
    @IBAction func close(sender: UIButton) {
        if isBroadcasting {
            stop()
            let streamer = Streamer.instance() as! Streamer
            streamer.stopVideoCapture()
            streamer.stopAudioCapture()
        }
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func finishTitleInput(sender: UIButton) {
        composeBar.resignFirstResponder()
        if isBroadcasting {
            composeBar.setDoneButtonHidden(true)
        } else {
            if let text = composeBar.text, let uuid = User.currentUser?.uid where !text.isEmpty {
                chatSubscription?.send([
                    "chatMessage" : text,
                    "userUid" : uuid
                    ])
            }
            composeBar.text = nil
        }
    }
    
    weak var focusView: UIView?
    
    func focusing(sender: UITapGestureRecognizer) {
        guard let layer = previewLayer, let session = layer.session where session.running else {
            return
        }
        
        self.focusView?.removeFromSuperview()
        
        let point = sender.locationInView(view)
        let pointOfInterest = layer.captureDevicePointOfInterestForPoint(point)
        
        guard let device = videoCamera() else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.focusPointOfInterestSupported && device.isFocusModeSupported(.AutoFocus) {
                device.focusPointOfInterest = pointOfInterest
                device.focusMode = .AutoFocus
            }
            if device.exposurePointOfInterestSupported && device.isExposureModeSupported(.AutoExpose) {
                device.exposurePointOfInterest = pointOfInterest
                device.exposureMode = .AutoExpose
            }
            device.unlockForConfiguration()
            let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 67, height: 67))
            focusView.center = point
            focusView.userInteractionEnabled = false
            focusView.backgroundColor = UIColor.clearColor()
            focusView.borderColor = Color.orange.colorWithAlphaComponent(0.5)
            focusView.borderWidth = 1
            view.addSubview(focusView)
            self.focusView = focusView
            UIView.animateWithDuration(0.33, delay: 1.0, options: .CurveEaseInOut, animations: { () -> Void in
                focusView.alpha = 0.0
                }) { (_) -> Void in
                    focusView.removeFromSuperview()
            }
        } catch {
        }
    }
    
    private func videoCamera() -> AVCaptureDevice? {
        guard let session = previewLayer?.session where session.running else {
            return nil
        }
        for input in session.inputs {
            if let input = input as? AVCaptureDeviceInput where input.device.hasMediaType(AVMediaTypeVideo) {
                return input.device
            }
        }
        return nil
    }
    
    func zooming(sender: UIPinchGestureRecognizer) {
        
        guard let device = videoCamera() else {
            return
        }
        
        let maxZoomScale = min(8, device.activeFormat.videoMaxZoomFactor)
        let zoomScale = max(1, min(maxZoomScale, sender.scale * device.videoZoomFactor))
        
        if (device.videoZoomFactor != zoomScale) {
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = zoomScale
                device.unlockForConfiguration()
            } catch {
            }
        }
        
        sender.scale = 1
    }
}

extension LiveBroadcastViewController: WLComposeBarDelegate {
    
    func composeBarDidShouldResignOnFinish(composeBar: WLComposeBar!) -> Bool {
        return true
    }
}

extension LiveBroadcastViewController: StreamerListener {
    
    @objc(connectionStateDidChangeId:State:Status:)
    func connectionStateDidChangeId(connectionID: Int32, state: ConnectionState, status: ConnectionStatus) {
        if self.connectionID == connectionID && state == .Disconnected {
            stop()
            let delay: Int64 = status == .UnknownFail ? 1 : 3
            weak var weakSelf = self
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue()) {
                do {
                    try weakSelf?.start()
                } catch {
                }
            }
        }
    }

    func videoCaptureStateDidChange(state: CaptureState) {

    }

    func audioCaptureStateDidChange(state: CaptureState) {

    }
}

extension LiveBroadcastViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        guard let wrap = wrap, let broadcast = broadcast else { return }
        guard event == .LiveBroadcastsChanged else { return }
        if !isBroadcasting && !wrap.liveBroadcasts.contains(broadcast) {
            presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        } else {
            updateBroadcastInfo()
        }
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil);
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
}

extension LiveBroadcastViewController: NotificationSubscriptionDelegate {
    func notificationSubscription(subscription: NotificationSubscription, didReceiveMessage message: PNMessageResult) {
        guard let broadcast = broadcast else { return }
        guard let uuid = (message.data?.message as? [String : AnyObject])?["userUid"] as? String else { return }
        guard let user = User.entry(uuid) else { return }
        guard let text = (message.data?.message as? [String : AnyObject])?["chatMessage"] as? String else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            let event = LiveBroadcast.Event(type: .Message)
            event.user = user
            event.text = text
            broadcast.insert(event)
            self?.chatDataSource.items = broadcast.events
            }, failure: nil)
    }
    
    private func setNumberOfViewers(numberOfViewers: Int) {
        guard let broadcast = broadcast else { return }
        broadcast.numberOfViewers = numberOfViewers
        if isBroadcasting {
            var state = userState
            state["numberOfViewers"] = numberOfViewers
            userState = state
        }
        updateBroadcastInfo()
    }
    
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult) {
        guard let broadcast = broadcast else { return }
        guard let uuid = event.data?.presence?.uuid where uuid != User.channelName() else { return }
        guard let user = PubNub.userFromUUID(uuid) where !user.current else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            guard let controller = self else {
                return
            }
            switch event.data.presenceEvent {
            case "join":
                let event = LiveBroadcast.Event(type: .Join)
                event.user = user
                broadcast.insert(event)
                controller.chatDataSource.items = broadcast.events
                controller.setNumberOfViewers(max(1, broadcast.numberOfViewers + 1))
                break
            case "leave", "timeout":
                self?.setNumberOfViewers(max(1, broadcast.numberOfViewers - 1))
                break
            default: break
            }
            }, failure: nil)
        
    }
}
