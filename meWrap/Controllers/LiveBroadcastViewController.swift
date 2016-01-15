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
    
    @IBOutlet weak var sendButton: UIButton!
    
    var chatDataSource: StreamDataSource!
    
    weak var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            if let layer = oldValue {
                layer.removeFromSuperlayer()
            }
            if let layer = previewLayer {
                layer.frame = view.bounds
                layer.videoGravity = AVLayerVideoGravityResizeAspectFill
                view.layer.insertSublayer(layer, atIndex: 0)
            }
        }
    }
    
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
    
    var chatSubscription: NotificationSubscription?
    
    var cameraPosition: Int32 = 1
    
    let streamer: Streamer = Streamer.instance() as! Streamer
    
    var allowAutorotate = true
    
    var userState = [NSObject:AnyObject]() {
        didSet {
            if let channel = wrap?.uid, let uuid = User.currentUser?.uid {
                userState["userUid"] = uuid
                NotificationCenter.defaultCenter.userSubscription.changeState(userState, channel: channel)
            }
        }
    }
    
    deinit {
        UIApplication.sharedApplication().idleTimerDisabled = false
        guard let item = playerItem else { return }
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
    
    private func updateBroadcastInfo() {
        joinsCountLabel.text = "\(max(0, broadcast.viewers.count))"
        titleLabel?.text = broadcast.displayTitle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        chatStreamView.layer.geometryFlipped = true
        
        chatDataSource = StreamDataSource(streamView: chatStreamView)
        chatDataSource.addMetrics(StreamMetrics(loader: IndexedStreamLoader(identifier: "LiveBroadcastEventViews", index: 0))).change { (metrics) -> Void in
            metrics.sizeAt = { [weak self] item -> CGFloat in
                let event = item.entry as? LiveBroadcast.Event
                return self?.chatStreamView?.dynamicSizeForMetrics(metrics, entry: event, minSize: 72) ?? 72
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
                return self?.chatStreamView?.dynamicSizeForMetrics(metrics, entry: event, minSize: 32) ?? 32
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
        composeBar.placeholder = "view_broadcast_text_placeholder".ls
        toggleCameraButton.hidden = true
        
        layoutPrioritizer.defaultState = false
        startButton.hidden = true
        sendButton.highlighted = true
        
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
        
        Dispatch.mainQueue.after(0.5) { () -> Void in
            PubNub.sharedInstance.hereNowForChannel("ch-\(broadcast.streamName)", withVerbosity: .UUID) { [weak self] (result, status) -> Void in
                if let uuids = result?.data?.uuids as? [String] {
                    var viewers = Set<User>()
                    for uuid in uuids {
                        guard let user = PubNub.userFromUUID(uuid) else { return }
                        user.fetchIfNeeded(nil, failure: nil)
                        if user != broadcast.broadcaster {
                            viewers.insert(user)
                        }
                    }
                    if let user = User.currentUser where !viewers.contains(user) {
                        viewers.insert(user)
                    }
                    broadcast.viewers = viewers
                    self?.updateBroadcastInfo()
                }
            }
        }
    }
    
    private func subscribe(broadcast: LiveBroadcast) {
        let chatSubscription = NotificationSubscription(name: "ch-\(broadcast.streamName)", isGroup: false, observePresence: true)
        chatSubscription.delegate = self
        chatSubscription.subscribe()
        self.chatSubscription = chatSubscription
    }
    
    private func initializeBroadcasting() {
        chatStreamView.hidden = true
        joinsCountView.hidden = true
        toggleCameraButton.hidden = true
        titleLabel?.superview?.hidden = true
        startCapture(1)
    }
    
    private func startCapture(position: Int32) {
        startVideoCapture(position)
        startAudioCapture()
    }
    
    private func startVideoCapture(position: Int32) {
        cameraPosition = position
        let cameras = CameraInfo.getCameraList() as? [CameraInfo]
        guard let cameraInfo = cameras?.filter({ $0.position == position }).first else { return }
        
        let videoConfig = VideoConfig()
        
        let videoSizes: [CGSize] = (cameraInfo.videoSizes as? [NSValue])?.map({ $0.CGSizeValue() }) ?? []
        let preferedSize = videoSizes.filter({ $0.width == 352 && $0.height == 288 }).first
        videoConfig.videoSize = preferedSize ?? videoSizes[0]
        videoConfig.bitrate = 2000000
        videoConfig.fps = 30
        videoConfig.keyFrameInterval = 2
        videoConfig.profileLevel = VideoConfig.getSupportedProfiles().first as! String
        
        let orientation: AVCaptureVideoOrientation = orientationForVideoConnection()
        if let layer = streamer.startVideoCaptureWithCamera(cameraInfo.cameraID, orientation: orientation, config: videoConfig, listener: self) {
            previewLayer = layer
            layer.connection.videoOrientation = orientation
            if let device = videoCamera() {
                do {
                    try device.lockForConfiguration()
                    if device.isFocusModeSupported(.ContinuousAutoFocus) {
                        device.focusMode = .ContinuousAutoFocus
                    }
                    if device.isExposureModeSupported(.ContinuousAutoExposure) {
                        device.exposureMode = .ContinuousAutoExposure
                    }
                    device.unlockForConfiguration()
                } catch { }
            }
        }
    }
    
    private func startAudioCapture() {
        let audioConfig = AudioConfig()
        audioConfig.sampleRate = (AudioConfig.getSupportedSampleRates().first as! NSNumber).floatValue
        streamer.startAudioCaptureWithConfig(audioConfig, listener: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation { [unowned self] () -> Void in
            if let layer = self.previewLayer {
                layer.frame = self.view.bounds
                layer.frame = self.view.bounds
                layer.connection?.videoOrientation = self.orientationForPreview()
            }
        }
    }
    
    private func orientationForVideoConnection() -> AVCaptureVideoOrientation {
        switch DeviceManager.defaultManager.orientation {
        case .Portrait: return .Portrait
        case .PortraitUpsideDown: return .PortraitUpsideDown
        case .LandscapeRight: return .LandscapeLeft
        default: return .LandscapeRight
        }
    }
    
    private func orientationForPreview() -> AVCaptureVideoOrientation {
        switch DeviceManager.defaultManager.orientation {
        case .Portrait: return .Portrait
        case .PortraitUpsideDown: return .PortraitUpsideDown
        case .LandscapeRight: return .LandscapeLeft
        default: return .LandscapeRight
        }
    }
    
    private func stopCapture() {
        streamer.stopVideoCapture()
        streamer.stopAudioCapture()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let keyPath = keyPath, let item = playerItem else { return }
        switch keyPath {
        case "status" where item.status == .ReadyToPlay, "playbackLikelyToKeepUp" where item.playbackLikelyToKeepUp == true:
            playerLayer?.player?.play()
        default: break
        }
    }
    
    func startBroadcast() {
        
        guard let wrap = wrap else { return }
        guard let user = User.currentUser else { return }
        guard let deviceUID = Authorization.currentAuthorization.deviceUID else { return }
        
        titleLabel?.text = composeBar.text
        titleLabel?.superview?.hidden = false
        
        let streamName = "\(wrap.uid)-\(user.uid)-\(deviceUID)"
        
        broadcast.title = composeBar.text
        
        broadcast.broadcaster = user
        broadcast.streamName = streamName
        broadcast.wrap = wrap
        wrap.addBroadcast(broadcast)
        
        createConnection(streamName)
        
        subscribe(broadcast)
        updateBroadcastInfo()
    }
    
    private func createConnection(streamName: String) {
        let uri = "rtsp://live.mewrap.me:1935/live/\(streamName)"
        connectionID = streamer.createConnectionWithListener(self, uri: uri, mode: 0)
    }
    
    private func releaseConnection() {
        if let connectionID = connectionID {
            self.connectionID = nil
            streamer.releaseConnectionId(connectionID)
        }
    }
    
    func stopBroadcast() {
        userState = [NSObject : AnyObject]()
        wrap?.removeBroadcast(broadcast)
        releaseConnection()
        stopCapture()
    }
    
    @IBAction func startBroadcast(sender: UIButton) {
        if composeBar.isFirstResponder() {
            composeBar.resignFirstResponder()
        }
        startBroadcast()
        joinsCountView.hidden = false
        chatStreamView.hidden = false
        toggleCameraButton.hidden = false
        sender.hidden = true
        composeBar.hidden = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "focusing:"))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "zooming:"))
        
        let preparingEvent = LiveBroadcast.Event(type: .Info)
        preparingEvent.text = "preparing_broadcast".ls
        preparingEvent.autoDismiss = false
        broadcast.insert(preparingEvent)
        chatDataSource.items = broadcast.events
        
        Dispatch.mainQueue.after(6) { [weak self] _ in
            
            guard let _self = self else { return }
            guard let wrap = _self.wrap else { return }
            guard let user = User.currentUser else { return }
            guard let deviceUID = Authorization.currentAuthorization.deviceUID else { return }
            
            let broadcast = _self.broadcast
            
            var state = [NSObject:AnyObject]()
            state["streamName"] = broadcast.streamName
            if let title = broadcast.title {
                state["title"] = title
            }
            _self.userState = state
            
            var message: [NSObject : AnyObject] = [
                "msg_type" : NotificationType.LiveBroadcast.rawValue,
                "wrap_uid" : wrap.uid,
                "user_uid" : user.uid,
                "device_uid" : deviceUID,
                "title" : broadcast.title ?? ""
            ]
            
            var pushPayload: [NSObject : AnyObject] = message
            pushPayload["aps"] = [
                "alert" : [
                    "title-loc-key" : "APNS_TT08",
                    "loc-key" : "APNS_MSG08",
                    "loc-args" : [user.name ?? "", broadcast.displayTitle(), wrap.name ?? ""]
                ],
                "sound" : "s01.wav",
                "content-available" : 1
            ]
            
            message["pn_apns"] = pushPayload
            
            PubNub.sharedInstance.publish(message, toChannel: wrap.uid, withCompletion: nil)
            
            let liveEvent = LiveBroadcast.Event(type: .Info)
            liveEvent.text = String(format: "formatted_you_are_now_live".ls, wrap.name ?? "")
            broadcast.insert(liveEvent)
            broadcast.remove(preparingEvent)
            _self.chatDataSource.items = broadcast.events
        }
        
        allowAutorotate = false
    }
    
    @IBAction func toggleCamera() {
        releaseConnection()
        stopCapture()
        startCapture(cameraPosition == 1 ? 2 : 1)
        createConnection(broadcast.streamName)
    }
    
    @IBAction func close(sender: UIButton) {
        if isBroadcasting {
            stopBroadcast()
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
                    "content" : text,
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
        } catch { }
    }
    
    private func videoInput(session: AVCaptureSession) -> AVCaptureDeviceInput? {
        for input in session.inputs {
            if let input = input as? AVCaptureDeviceInput where input.device.hasMediaType(AVMediaTypeVideo) {
                return input
            }
        }
        return nil
    }
    
    private func videoCamera() -> AVCaptureDevice? {
        guard let session = previewLayer?.session else { return nil }
        return videoInput(session)?.device
    }
    
    func zooming(sender: UIPinchGestureRecognizer) {
        
        guard let device = videoCamera() else { return }
        
        let maxZoomScale = min(8, device.activeFormat.videoMaxZoomFactor)
        let zoomScale = max(1, min(maxZoomScale, sender.scale * device.videoZoomFactor))
        
        if (device.videoZoomFactor != zoomScale) {
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = zoomScale
                device.unlockForConfiguration()
            } catch { }
        }
        
        sender.scale = 1
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

extension LiveBroadcastViewController: WLComposeBarDelegate {
    
    func composeBarDidShouldResignOnFinish(composeBar: WLComposeBar!) -> Bool {
        return true
    }
}

extension LiveBroadcastViewController: StreamerListener {
    
    @objc(connectionStateDidChangeId:State:Status:)
    func connectionStateDidChangeId(connectionID: Int32, state: ConnectionState, status: ConnectionStatus) {
        if self.connectionID == connectionID && state == .Disconnected {
            releaseConnection()
            Dispatch.mainQueue.after(status == .UnknownFail ? 1 : 3, block: { [weak self] () -> Void in
                self?.startBroadcast()
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
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
}

extension LiveBroadcastViewController: NotificationSubscriptionDelegate {
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
