//
//  LiveBroadcasterViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

private let LiveBroadcastUsername = "ravenpod"
private let LiveBroadcastPassword = "34f82ab09fb501330b3910ddb1e38026"

class LiveBroadcasterViewController: LiveViewController {

    var cameraPosition: Int32 = 1
    
    let streamer: Streamer = Streamer.instance() as! Streamer
    
    private var connectionID: Int32?
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var toggleCameraButton: UIButton!
    
    weak var focusView: UIView?
    
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
    
    var userState = [NSObject:AnyObject]() {
        didSet {
            if let channel = wrap?.uid, let uuid = User.currentUser?.uid {
                userState["userUid"] = uuid
                NotificationCenter.defaultCenter.userSubscription.changeState(userState, channel: channel)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "applicationWillTerminate:", name: UIApplicationWillTerminateNotification, object: nil)
        center.addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
        center.addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.composeBar.text = self.broadcast.title
        chatStreamView.hidden = true
        joinsCountView.hidden = true
        titleLabel?.superview?.hidden = true
        startCapture(cameraPosition)
        UIAlertController.showNoMediaAccess(true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation { [unowned self] () -> Void in
            if let layer = self.previewLayer {
                layer.frame = self.view.bounds
                if self.allowAutorotate {
                    layer.connection?.videoOrientation = self.orientationForVideoConnection()
                }
            }
        }
    }
    
    private func orientationForVideoConnection() -> AVCaptureVideoOrientation {
        let orientation = DeviceManager.defaultManager.orientation
        switch orientation {
        case .LandscapeLeft: return .LandscapeRight
        case .PortraitUpsideDown: return .PortraitUpsideDown
        case .LandscapeRight: return .LandscapeLeft
        default: return .Portrait
        }
    }

    func applicationWillTerminate(notification: NSNotification) {
        stopBroadcast()
    }
    
    func applicationWillResignActive(notification: NSNotification) {
        stopBroadcast()
        view = nil
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        presentViewController(UIViewController(), animated: false, completion: nil)
        dismissViewControllerAnimated(false, completion: nil)
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
        let preferedSize = videoSizes.filter({ $0.width == 640 && $0.height == 480 }).first
        videoConfig.videoSize = preferedSize ?? videoSizes[3]
        videoConfig.bitrate = 280000
        videoConfig.fps = 15
        videoConfig.keyFrameInterval = 2
        let profiles = VideoConfig.getSupportedProfiles() as! [String]
        videoConfig.profileLevel = profiles[0]
        
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
        audioConfig.bitrate = 32000
        audioConfig.channelCount = 1
        audioConfig.sampleRate = 44100
        streamer.startAudioCaptureWithConfig(audioConfig, listener: self)
    }
    
    private func stopCapture() {
        streamer.stopVideoCapture()
        streamer.stopAudioCapture()
    }
    
    func startBroadcast() {
        
        guard let wrap = wrap else { return }
        guard let user = User.currentUser else { return }
        let deviceUID = Authorization.currentAuthorization.deviceUID
        
        titleLabel?.text = composeBar.text
        titleLabel?.superview?.hidden = false
        
        broadcast.title = composeBar.text
        
        broadcast.broadcaster = user
        broadcast.streamName = "\(wrap.uid)-\(user.uid)-\(deviceUID)"
        broadcast.wrap = wrap
        
        createConnection()
        
        subscribe(broadcast)
        updateBroadcastInfo()
    }
    
    private func createConnection() {
        let uri = "rtsp://\(LiveBroadcastUsername):\(LiveBroadcastPassword)@live.mewrap.me:1935/live/\(broadcast.streamName)"
        connectionID = streamer.createConnectionWithListener(self, uri: uri, mode: 0)
    }
    
    private func releaseConnection() {
        startEventIsAlreadyPresented = false
        if let connectionID = connectionID {
            self.connectionID = nil
            streamer.releaseConnectionId(connectionID)
        }
    }
    
    func stopBroadcast() {
        userState = [NSObject : AnyObject]()
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
        toggleCameraButton.hidden = true
        sender.hidden = true
        composeBar.hidden = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "focusing:"))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "zooming:"))
        
        Dispatch.mainQueue.after(6) { [weak self] _ in
            
            guard let _self = self else { return }
            guard let wrap = _self.wrap else { return }
            guard let user = User.currentUser else { return }
            
            let broadcast = _self.broadcast
            
            var state = [NSObject:AnyObject]()
            state["streamName"] = broadcast.streamName
            if let title = broadcast.title {
                state["title"] = title
            }
            _self.userState = state
            
            let message: [NSObject : AnyObject] = [
                "pn_apns" : [
                    "aps" : [
                        "alert" : [
                            "title-loc-key" : "APNS_TT08",
                            "loc-key" : "APNS_MSG08",
                            "loc-args" : [user.name ?? "", broadcast.displayTitle(), wrap.name ?? ""]
                        ],
                        "sound" : "s01.wav",
                        "content-available" : 1
                    ],
                    "stream_info" : [
                        "wrap_uid" : wrap.uid,
                        "user_uid" : user.uid,
                        "device_uid" : Authorization.currentAuthorization.deviceUID,
                        "title" : broadcast.title ?? ""
                    ],
                    "msg_type" : NotificationType.LiveBroadcast.rawValue
                ],
                "msg_type" : NotificationType.LiveBroadcast.rawValue
            ]
            
            PubNub.sharedInstance.publish(message, toChannel: wrap.uid, withCompletion: nil)
            
            let liveEvent = LiveBroadcast.Event(kind: .Info)
            liveEvent.text = String(format: "formatted_broadcast_notification".ls, wrap.name ?? "")
            broadcast.insert(liveEvent)
            _self.chatDataSource.items = broadcast.events
        }
        
        allowAutorotate = false
    }
    
    @IBAction func toggleCamera() {
        stopCapture()
        startCapture(cameraPosition == 1 ? 2 : 1)
    }
    
    internal override func close() {
        stopBroadcast()
        super.close()
    }
    
    @IBAction func finishTitleInput(sender: AnyObject?) {
        composeBar.resignFirstResponder()
        composeBar.setDoneButtonHidden(true)
    }
    
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
    
    override func wrapLiveBroadcastsUpdated() {
        updateBroadcastInfo()
    }
    
    private var startEventIsAlreadyPresented = false
}

extension LiveBroadcasterViewController: StreamerListener {
    
    @objc(connectionStateDidChangeId:State:Status:)
    func connectionStateDidChangeId(connectionID: Int32, state: ConnectionState, status: ConnectionStatus) {
        
        guard self.connectionID == connectionID else {
            return
        }
        
        if state == .Record && !startEventIsAlreadyPresented {
            startEventIsAlreadyPresented = true
            let liveEvent = LiveBroadcast.Event(kind: .Info)
            liveEvent.text = String(format: "your_broadcast_is_live".ls)
            broadcast.insert(liveEvent)
            chatDataSource.items = broadcast.events
        }
        
        if state == .Disconnected {
            #if DEBUG
                Toast.show("Reconnecting...")
            #endif
            releaseConnection()
            Dispatch.mainQueue.after(status == .UnknownFail ? 1 : 3, block: { [weak self] () -> Void in
                self?.createConnection()
                })
        }
    }
    
    func videoCaptureStateDidChange(state: CaptureState) { }
    
    func audioCaptureStateDidChange(state: CaptureState) { }
}
