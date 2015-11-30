//
//  LiveBroadcastViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

import AVFoundation

class LiveBroadcastViewController: WLBaseViewController {
    
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
    
    weak var broadcast: LiveBroadcast?
    
    deinit {
        guard let item = playerItem else {
            return
        }
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wrapNameLabel?.text = wrap?.name
        
        if let broadcast = broadcast {
            isBroadcasting = false
            titleLabel?.text = broadcast.title
            composeBar.hidden = true
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
            }
        } else {
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
        Wrap.notifier().addReceiver(self)
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
    
    func start() {
        titleLabel?.text = composeBar.text
        titleLabel?.superview?.hidden = false
        
        let streamer = Streamer.instance() as! Streamer
        guard let userUID = User.currentUser?.identifier,
            let deviceUID = Authorization.currentAuthorization.deviceUID else {
            return
        }
        let channel = "\(userUID)-\(deviceUID)"
        
        let broadcast = LiveBroadcast()
        broadcast.title = composeBar.text
        broadcast.broadcaster = User.currentUser
        broadcast.url = "http://live.mewrap.me:1935/live/\(channel)/playlist.m3u8"
        broadcast.channel = channel
        broadcast.wrap = wrap
        LiveBroadcast.addBroadcast(broadcast)
        
        print(broadcast.url)
        
        self.broadcast = broadcast
        
        let state: [NSObject : AnyObject] = [
            "isBroadcasting":true,
            "title":broadcast.title,
            "viewerURL":broadcast.url,
            "chatChannel":channel
        ]
        
        if let channel = wrap?.identifier {
            WLNotificationCenter.defaultCenter().userSubscription.changeState(state, channel: channel)
        }
        
        let uri = "rtsp://live.mewrap.me:1935/live/\(channel)"
        connectionID = streamer.createConnectionWithListener(self, uri: uri, mode: 0)
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    func stop() {
        
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        if let broadcast = broadcast {
            LiveBroadcast.removeBroadcast(broadcast)
        }
        if let channel = wrap?.identifier {
            let state: [NSObject : AnyObject] = [ "isBroadcasting":false ]
            WLNotificationCenter.defaultCenter().userSubscription.changeState(state, channel: channel)
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
            start()
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
        composeBar.setDoneButtonHidden(true)
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
                weakSelf?.start()
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
        guard let wrap = wrap, let broadcast = broadcast else {
            return
        }
        guard !isBroadcasting && event == .LiveBroadcastsChanged else {
            return
        }
        guard let broadcasts = LiveBroadcast.broadcastsForWrap(wrap) where !broadcasts.contains(broadcast) else {
            return
        }
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil);
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil);
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
}
