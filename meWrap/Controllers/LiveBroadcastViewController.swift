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

class LiveBroadcastViewController: WLBaseViewController {
    
    @IBOutlet var layoutPrioritizer: LayoutPrioritizer!
    
    @IBOutlet weak var joinsCountView: UIView!
    
    @IBOutlet weak var joinsCountLabel: UILabel!
    
    @IBOutlet weak var toggleCameraButton: UIButton!
    
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
    
    lazy var broadcast: LiveBroadcast = LiveBroadcast()
    
    var preparingEvent: LiveBroadcast.Event?
    
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
        joinsCountLabel.text = "\(broadcast.numberOfViewers)"
        titleLabel?.text = broadcast.title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        chatStreamView.layer.geometryFlipped = true
        
        chatDataSource = StreamDataSource(streamView: chatStreamView)
        chatDataSource.addMetrics(StreamMetrics(loader: IndexedStreamLoader(identifier: "LiveBroadcastEventViews", index: 0))).change { (metrics) -> Void in
            metrics.sizeAt = { [weak self] item -> CGFloat in
                let event = item.entry as? LiveBroadcast.Event
                if let streamView = self?.chatStreamView {
                    return max(streamView.dynamicSizeForMetrics(metrics, entry: event), 72)
                } else {
                    return 72
                }
            }
            metrics.hiddenAt = { item -> Bool in
                let event = item.entry as? LiveBroadcast.Event
                return event?.type != .Message
            }
            metrics.insetsAt = { CGRect(x: 0, y: $0.position.index == 0 ? 0 : 6, width: 0, height: 0) }
        }
        chatDataSource.addMetrics(StreamMetrics(loader: IndexedStreamLoader(identifier: "LiveBroadcastEventViews", index: 1))).change { (metrics) -> Void in
            metrics.sizeAt = { [weak self] item -> CGFloat in
                let event = item.entry as? LiveBroadcast.Event
                if let streamView = self?.chatStreamView {
                    return max(streamView.dynamicSizeForMetrics(metrics, entry: event), 32)
                } else {
                    return 32
                }
            }
            metrics.hiddenAt = { item -> Bool in
                let event = item.entry as? LiveBroadcast.Event
                return event?.type != .Info
            }
            metrics.insetsAt = { CGRect(x: 0, y: $0.position.index == 0 ? 0 : 6, width: 0, height: 0) }
        }
        
        wrapNameLabel?.text = wrap?.name
        
        if broadcast.wrap != nil {
            initializeViewing(broadcast)
        } else {
            initializeBroadcasting()
        }
        Wrap.notifier().addReceiver(self)
    }
    
    private func initializeViewing(broadcast: LiveBroadcast) {
        isBroadcasting = false
        toggleCameraButton.hidden = true
        
        layoutPrioritizer.defaultState = false
        startButton.hidden = true
        
        guard let url = "http://live.mewrap.me:1935/live/\(broadcast.streamName)/playlist.m3u8".URL else { return }
        
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
        
        guard let wrap = wrap else { return }
        PubNub.sharedInstance.stateForUUID(broadcast.uuid, onChannel: wrap.uid) { [weak self] (result, status) -> Void in
            if let state = result?.data?.state, let numberOfViewers = state["numberOfViewers"] as? Int {
                broadcast.numberOfViewers = numberOfViewers
                self?.updateBroadcastInfo()
            }
            }
    }
    
    private func subscribe(broadcast: LiveBroadcast) {
        let chatSubscription = NotificationSubscription(name: broadcast.streamName, isGroup: false, observePresence: true)
        chatSubscription.delegate = self
        self.chatSubscription = chatSubscription
    }
    
    private func initializeBroadcasting() {
        chatStreamView.hidden = true
        joinsCountView.hidden = true
        toggleCameraButton.hidden = true
        isBroadcasting = true
        titleLabel?.superview?.hidden = true
        guard let cameraInfo = CameraInfo.getCameraList().first as? CameraInfo else { return }
        
        let videoConfig = VideoConfig()
        
        let videoSizes: [CGSize] = (cameraInfo.videoSizes as? [NSValue])?.map({ $0.CGSizeValue() }) ?? []
        let preferedSize = videoSizes.filter({ $0.width == 352 && $0.height == 288 }).first
        videoConfig.videoSize = preferedSize ?? videoSizes[0]
        videoConfig.bitrate = 2000000
        videoConfig.fps = 30
        videoConfig.keyFrameInterval = 2
        videoConfig.profileLevel = VideoConfig.getSupportedProfiles().first as! String
        
        let audioConfig = AudioConfig()
        audioConfig.sampleRate = (AudioConfig.getSupportedSampleRates().first as! NSNumber).floatValue
        let streamer = Streamer.instance() as! Streamer
        let orientation = orientationForVideoConnection()
        let layer = streamer.startVideoCaptureWithCamera(cameraInfo.cameraID, orientation: orientation, config: videoConfig, listener: self)
        layer.frame = view.bounds
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.insertSublayer(layer, atIndex: 0)
        streamer.startAudioCaptureWithConfig(audioConfig, listener: self)
        previewLayer = layer
    }
    
    private func orientationForVideoConnection() -> AVCaptureVideoOrientation {
        switch WLDeviceManager.defaultManager().orientation {
        case .PortraitUpsideDown: return .PortraitUpsideDown
        case .LandscapeLeft: return .LandscapeLeft
        case .LandscapeRight: return .LandscapeRight
        default: return .Portrait
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let keyPath = keyPath, let item = playerItem else { return }
        switch keyPath {
        case "status" where item.status == .ReadyToPlay, "playbackLikelyToKeepUp" where item.playbackLikelyToKeepUp == true:
            playerLayer?.player?.play()
        default: break
        }
    }
    
    func start() throws {
        
        guard let wrap = wrap else { throw NSError(message: "no wrap") }
        guard let user = User.currentUser else { throw NSError(message: "no user_uid") }
        guard let deviceUID = Authorization.currentAuthorization.deviceUID else { throw NSError(message: "no device_uid") }
        
        titleLabel?.text = composeBar.text
        titleLabel?.superview?.hidden = false
        
        let streamer = Streamer.instance() as! Streamer
        let streamName = "\(wrap.uid)-\(user.uid)-\(deviceUID)"
        
        broadcast.title = composeBar.text
        broadcast.broadcaster = user
        broadcast.streamName = streamName
        broadcast.uuid = User.channelName()
        broadcast.wrap = wrap
        wrap.addBroadcast(broadcast)
        
        userState = [
            "title" : broadcast.title,
            "streamName" : streamName,
            "numberOfViewers" : broadcast.numberOfViewers
        ]
        
        let uri = "rtsp://live.mewrap.me:1935/live/\(streamName)"
        connectionID = streamer.createConnectionWithListener(self, uri: uri, mode: 0)
        
        subscribe(broadcast)
        updateBroadcastInfo()
    }
    
    func stop() {
        userState = [NSObject : AnyObject]()
        wrap?.removeBroadcast(broadcast)
        
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
            toggleCameraButton.hidden = false
            sender.hidden = true
            composeBar.hidden = true
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "focusing:"))
            view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "zooming:"))
            
            let event = LiveBroadcast.Event(type: .Info)
            event.text = "preparing_broadcast".ls
            event.autoDismiss = false
            broadcast.insert(event)
            chatDataSource.items = broadcast.events
            preparingEvent = event
        }
    }
    
    @IBAction func toggleCamera() {
        if let session = previewLayer?.session {
            session.beginConfiguration()
            if let input = (session.inputs as? [AVCaptureDeviceInput])?.filter({ $0.device.hasMediaType(AVMediaTypeVideo) }).first {
                let position: AVCaptureDevicePosition = input.device.position == .Back ? .Front : .Back
                if let device = (AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as? [AVCaptureDevice])?.filter({ $0.position == position }).last {
                    do {
                        let _input = try AVCaptureDeviceInput(device: device)
                        session.removeInput(input)
                        if session.canAddInput(_input) {
                            session.addInput(_input)
                        }
                    } catch {
                    }
                }
            }
            session.commitConfiguration()
            
            let orientation = orientationForVideoConnection()
            if let outputs = session.outputs as? [AVCaptureOutput] {
                for output in outputs {
                    if let connection = output.connectionWithMediaType(AVMediaTypeVideo) {
                        connection.videoOrientation = orientation
                    }
                }
            }
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
        
        if state == .Record {
            let event = LiveBroadcast.Event(type: .Info)
            event.text = String(format: "formatted_you_are_now_live".ls, wrap?.name ?? "")
            broadcast.insert(event)
            if let preparingEvent = preparingEvent {
                broadcast.remove(preparingEvent)
            }
            chatDataSource.items = broadcast.events
        }
        
        if self.connectionID == connectionID && state == .Disconnected {
            stop()
            Dispatch.mainQueue.after(status == .UnknownFail ? 1 : 3, block: { [weak self] () -> Void in
                do {
                    try self?.start()
                } catch { }
            })
        }
    }

    func videoCaptureStateDidChange(state: CaptureState) { }

    func audioCaptureStateDidChange(state: CaptureState) { }
}

extension LiveBroadcastViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        guard let wrap = wrap else { return }
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
        guard let uuid = (message.data?.message as? [String : AnyObject])?["userUid"] as? String else { return }
        guard let user = User.entry(uuid) else { return }
        guard let text = (message.data?.message as? [String : AnyObject])?["chatMessage"] as? String else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            let event = LiveBroadcast.Event(type: .Message)
            event.user = user
            event.text = text
            self?.broadcast.insert(event)
            self?.chatDataSource.items = self?.broadcast.events
            }, failure: nil)
    }
    
    private func setNumberOfViewers(numberOfViewers: Int) {
        broadcast.numberOfViewers = numberOfViewers
        if isBroadcasting {
            var state = userState
            state["numberOfViewers"] = numberOfViewers
            userState = state
        }
        updateBroadcastInfo()
    }
    
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult) {
        guard let uuid = event.data?.presence?.uuid where uuid != User.channelName() else { return }
        guard let user = PubNub.userFromUUID(uuid) where !user.current else { return }
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            guard let broadcast = self?.broadcast else { return }
            guard let controller = self else { return }
            switch event.data.presenceEvent {
            case "join":
                let event = LiveBroadcast.Event(type: .Info)
                event.text = "\(user.name ?? "") \("joined".ls)"
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
