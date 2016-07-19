//
//  LiveBroadcasterViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import PubNub
import WowzaGoCoderSDK
import AVFoundation

private let LiveBroadcastUsername = "ravenpod"
private let LiveBroadcastPassword = "34f82ab09fb501330b3910ddb1e38026"

final class Streamer: NSObject, WZStatusCallback {
    
    static let streamer = Streamer()
    
    static let registered = WowzaGoCoder.registerLicenseKey("GSDK-4E42-0000-E695-47D9-23F7") == nil
    
    var goCoder: WowzaGoCoder? {
        if Streamer.registered {
            return WowzaGoCoder.sharedInstance()
        } else {
            return nil
        }
    }
    
    func start(success: () -> (), failure: FailureBlock) {
        streamingStarted = success
        self.failure = failure
        goCoder?.startStreaming(self)
    }
    
    func stop() {
        goCoder?.endStreaming(self)
    }
    
    func onWZError(status: WZStatus!) {
        Dispatch.mainQueue.async({ () in
            self.failure?(status.error)
            self.failure = nil
            self.streamingStarted = nil
        })
    }
    
    func onWZEvent(status: WZStatus!) {}
    
    private var streamingStarted: (() -> ())?
    
    private var failure: FailureBlock?
    
    func onWZStatus(status: WZStatus!) {
        if status.state == .Running {
            Dispatch.mainQueue.async({ () in
                self.streamingStarted?()
                self.streamingStarted = nil
                self.failure = nil
            })
        }
    }
}

final class LiveBroadcasterViewController: LiveViewController {
    
    private let startButton = Button()
    
    private let toggleCameraButton = Button(icon: "}", size: 18, textColor: UIColor.whiteColor())
    
    weak var focusView: UIView?
    
    deinit {
        stopBroadcast()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func loadView() {
        super.loadView()
        
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: #selector(self.applicationWillTerminate(_:)), name: UIApplicationWillTerminateNotification, object: nil)
        center.addObserver(self, selector: #selector(self.applicationWillResignActive(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(self.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        startButton.backgroundColor = Color.orange
        startButton.normalColor = Color.orange
        startButton.highlightedColor = Color.orangeDarker
        startButton.addTarget(self, touchUpInside: #selector(self.startBroadcast(_:)))
        startButton.cornerRadius = 36
        startButton.clipsToBounds = true
        startButton.setBorder(width: 4)
        view.add(startButton) { (make) in
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).inset(12)
            make.size.equalTo(72)
        }
        
        composeBar.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(startButton.snp_top).inset(-12)
        }
        
        Keyboard.keyboard.handle(self, willShow: { [unowned self] (keyboard) in
            keyboard.performAnimation { () in
                self.composeBar.snp_remakeConstraints { (make) in
                    make.leading.trailing.equalTo(self.view)
                    make.bottom.equalTo(self.view).inset(keyboard.height)
                }
                self.view.layoutIfNeeded()
            }
        }) { [unowned self] (keyboard) in
            keyboard.performAnimation { () in
                self.composeBar.snp_remakeConstraints { (make) in
                    make.leading.trailing.equalTo(self.view)
                    make.bottom.equalTo(self.startButton.snp_top).inset(-12)
                }
                self.view.layoutIfNeeded()
            }
        }
        
        toggleCameraButton.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        toggleCameraButton.normalColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        toggleCameraButton.highlightedColor = Color.grayLighter
        toggleCameraButton.cornerRadius = 22
        toggleCameraButton.clipsToBounds = true
        toggleCameraButton.setBorder(width: 2)
        toggleCameraButton.addTarget(self, touchUpInside: #selector(self.toggleCamera))
        view.add(toggleCameraButton) { (make) in
            make.trailing.equalTo(view).inset(12)
            make.bottom.equalTo(composeBar.snp_top).inset(-12)
            make.size.equalTo(44)
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.focusing(_:))))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(self.zooming(_:))))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !Streamer.registered {
            Dispatch.mainQueue.async({ () in
                self.navigationController?.popViewControllerAnimated(false)
            })
            return
        }
        
        AudioSession.mode = AVAudioSessionModeVideoRecording
        AudioSession.category = AVAudioSessionCategoryRecord
        
        let goCoder = Streamer.streamer.goCoder
        
        goCoder?.cameraView = view
        if let wrap = wrap, let goCoder = goCoder, let preview = goCoder.cameraPreview {
            
            broadcast.broadcaster = User.currentUser
            broadcast.streamName = "\(wrap.uid)-\(User.uuid())"
            broadcast.wrap = wrap
            
            goCoder.config = specify(goCoder.config, { config in
                //
                // We should not use preset .Preset640x480 because that 
                // doesn't allow us to specify the lower video bitrate as 280K.
                // With default 1.5Mbps, if broadcaster is under high speed internet
                // and is fully utilizing 1.5Mbps, viewers will suffer if they don't 
                // have high speed internet to catch up with the broadcaster's
                // fast-publishing pace.
                //
                // Therefore, we don't use preset and instead, we specify the video
                // width and height, as well as video bitrate so that we can control
                // the max video bitrate the broadcaster is publishing.
                //
                // videoBitrateLowBandwidthScalingFactor = 0.1 is used to handle
                // broadcaster's low speed interest situation (10% of 280K?)
                //
                // Frame rate and key frame interval should be 20/20. Default is 30/30.
                // Most people cannot see video frame rate higher than 24 and so 20 
                // should be sufficient enough
                //
                config.videoWidth = 640
                config.videoHeight = 480
                config.videoFrameRate = 20
                config.videoKeyFrameInterval = 20
                config.videoBitrate = 280000
                config.videoBitrateLowBandwidthScalingFactor = 0.1
                config.videoPreviewRotates = true
                
                config.hostAddress = "live.mewrap.me"
                config.applicationName = "live"
                config.portNumber = 1935
                config.username = LiveBroadcastUsername
                config.password = LiveBroadcastPassword
                config.streamName = broadcast.streamName
            })
            
            toggleCameraButton.hidden = preview.cameras?.count <= 1
            preview.previewGravity = .ResizeAspectFill
            
            preview.config = goCoder.config
            
            preview.startPreview()
        }
        
        composeBar.textView.placeholder = "broadcast_text_placeholder".ls
        composeBar.doneButton.setTitle("E", forState: .Normal)
        self.composeBar.text = self.broadcast.title
        joinsCountView.hidden = true
        titleLabel.superview?.hidden = true
        UIAlertController.showNoMediaAccess(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Streamer.streamer.goCoder?.cameraPreview?.previewLayer?.frame = view.bounds
    }
    
    override func requestPresentingPermission(completion: BooleanBlock) {
        UIAlertController.alert("live".ls, message: "end_live_streaming_confirmation".ls).action("no".ls, handler: { _ in
            completion(false)
        }).action("yes".ls, handler: { [weak self] _ in
            NotificationCenter.defaultCenter.setActivity(self?.wrap, type: .Live, inProgress: false)
            completion(true)
            }).show()
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
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        resetBroadcast()
    }
    
    private func resetBroadcast() {
        joinsCountView.hidden = true
        startButton.hidden = false
        composeBar.hidden = false
        composeBar.snp_remakeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(startButton.snp_top).inset(-12)
        }
        toggleCameraButton.snp_remakeConstraints { (make) in
            make.trailing.equalTo(view).inset(12)
            make.bottom.equalTo(composeBar.snp_top).inset(-12)
            make.size.equalTo(44)
        }
    }
    
    func startStreaming(completionHandler: () -> (), failure: FailureBlock) {
        titleLabel.text = composeBar.text
        titleLabel.superview?.hidden = false
        broadcast.title = composeBar.text
        Dispatch.defaultQueue.async { [weak self] () in
            Streamer.streamer.start({
                completionHandler()
                let liveEvent = LiveBroadcast.Event(kind: .Info)
                liveEvent.text = String(format: "your_broadcast_is_live".ls)
                self?.insertEvent(liveEvent)
            }, failure: failure)
            UIApplication.sharedApplication().idleTimerDisabled = true
        }
        chatSubscription.subscribe()
        updateBroadcastInfo()
    }
    
    func stopBroadcast() {
        if startButton.hidden {
            NotificationCenter.defaultCenter.setActivity(wrap, type: .Live, inProgress: false)
            Streamer.streamer.stop()
            chatSubscription.unsubscribe()
        }
    }
    
    @IBAction func startBroadcast(sender: UIButton) {
        if composeBar.isFirstResponder() {
            composeBar.resignFirstResponder()
        }
        
        if let error = Streamer.streamer.goCoder?.config.validateForBroadcast() {
            error.show()
            return
        }
        
        startStreaming({ [weak self] _ in
            
            guard self?.startButton.hidden == true else { return }
            
            Dispatch.mainQueue.after(6) {
                
                guard self?.startButton.hidden == true else { return }
                
                guard let _self = self else { return }
                guard let wrap = _self.wrap else { return }
                guard let user = User.currentUser else { return }
                
                let broadcast = _self.broadcast
                
                NotificationCenter.defaultCenter.setActivity(wrap, type: .Live, inProgress: true, info: [
                    "streamName" : broadcast.streamName,
                    "title" : broadcast.title ?? ""
                    ])
                
                let streamInfo = [
                    "wrap_uid" : wrap.uid,
                    "user_uid" : user.uid,
                    "device_uid" : Authorization.current.deviceUID,
                    "title" : broadcast.title ?? ""
                ]
                
                let message: [NSObject : AnyObject] = [
                    "pn_apns" : [
                        "aps" : [
                            "alert" : [
                                "title-loc-key" : "APNS_TT08",
                                "loc-key" : "APNS_MSG08",
                                "loc-args" : [user.name ?? "", broadcast.displayTitle(), wrap.name ?? ""]
                            ],
                            "sound" : "default",
                            "content-available" : 1
                        ],
                        "stream_info" : streamInfo,
                        "msg_type" : NotificationType.LiveBroadcast.rawValue
                    ],
                    "pn_gcm": [
                        "data": [
                            "message": [
                                "msg_uid" : NSProcessInfo.processInfo().globallyUniqueString,
                                "stream_info" : streamInfo,
                                "msg_type" : NotificationType.LiveBroadcast.rawValue
                            ]
                        ]
                    ],
                    "msg_type" : NotificationType.LiveBroadcast.rawValue
                ]
                
                PubNub.sharedInstance.publish(message, toChannel: wrap.uid, withCompletion: nil)
                
                let liveEvent = LiveBroadcast.Event(kind: .Info)
                liveEvent.text = String(format: "formatted_broadcast_notification".ls, wrap.name ?? "")
                _self.insertEvent(liveEvent)
            }
            }, failure: { [weak self] error in
                error?.show()
                self?.stopBroadcast()
                self?.resetBroadcast()
        })
        joinsCountView.hidden = false
        sender.hidden = true
        composeBar.hidden = true
        composeBar.snp_remakeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(view.snp_bottom)
        }
        toggleCameraButton.snp_remakeConstraints { (make) in
            make.trailing.equalTo(view).inset(12)
            make.bottom.equalTo(joinsCountView.snp_top).inset(-12)
            make.size.equalTo(44)
        }
    }
    
    func toggleCamera() {
        Streamer.streamer.goCoder?.cameraPreview?.switchCamera()
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        composeBar.resignFirstResponder()
        composeBar.setDoneButtonHidden(true, animated: true)
    }
    
    func focusing(sender: UITapGestureRecognizer) {
        
        if composeBar.isFirstResponder() {
            composeBar.resignFirstResponder()
            return
        }
        
        guard let layer = Streamer.streamer.goCoder?.cameraPreview?.previewLayer, let session = layer.session where session.running else { return }
        
        self.focusView?.removeFromSuperview()
        
        let point = sender.locationInView(view)
        let pointOfInterest = layer.captureDevicePointOfInterestForPoint(point)
        
        guard let device = videoCamera() else { return }
        
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
            focusView.setBorder(color: Color.orange.colorWithAlphaComponent(0.5))
            view.addSubview(focusView)
            self.focusView = focusView
            UIView.animateWithDuration(0.33, delay: 1.0, options: .CurveEaseInOut, animations: { () -> Void in
                focusView.alpha = 0.0
            }) { _ in focusView.removeFromSuperview() }
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
        guard let session = Streamer.streamer.goCoder?.cameraPreview?.previewLayer?.session else { return nil }
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
}
