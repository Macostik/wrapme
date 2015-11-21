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
    
    weak var playerLayer: AVPlayerLayer?
    
    @IBOutlet weak var wrapNameLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    private var connectionID: Int32?
    
    var wrap: Wrap?
    
    @IBOutlet weak var composeBar: WLComposeBar!
    
    @IBOutlet weak var startButton: UIButton!
    
    var isBroadcasting = false
    
    weak var broadcast: LiveBroadcast?
    
    deinit {
        guard let player = playerLayer?.player else {
            return
        }
        player.removeObserver(self, forKeyPath: "status")
        player.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        player.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
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
                
                let player = AVPlayer(URL: url)
                layer.player = player
                player.addObserver(self, forKeyPath: "status", options: .New, context: nil)
                player.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
                player.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .New, context: nil)
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
        }
        Wrap.notifier().addReceiver(self)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let player = playerLayer?.player else {
            return
        }
        if keyPath == "status" {
            if player.status == .ReadyToPlay {
                player.play()
            }
        } else if keyPath == "playbackLikelyToKeepUp" {
            if player.currentItem?.playbackLikelyToKeepUp == true {
                player.play()
            }
        } else if keyPath == "playbackBufferEmpty" {
            if player.currentItem?.playbackBufferEmpty == true {
                
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
        
    }
    
    func stop() {
        
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
