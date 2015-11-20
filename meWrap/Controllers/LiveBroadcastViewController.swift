//
//  LiveBroadcastViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class LiveBroadcastViewController: WLBaseViewController {
    
    @IBOutlet weak var wrapNameLabel: UILabel?
    
    private var connectionID: Int32?
    
    var wrap: Wrap?
    
    @IBOutlet weak var composeBar: WLComposeBar!
    
    @IBOutlet weak var startButton: UIButton!
    
    var broadcast: LiveBroadcast?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wrapNameLabel?.text = wrap?.name
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
    
    func start() {
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
        wrap?.notifyOnUpdate()
        
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
        stop()
        let streamer = Streamer.instance() as! Streamer
        streamer.stopVideoCapture()
        streamer.stopAudioCapture()
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
        if let connID = self.connectionID where connID == connectionID && state == .Disconnected {
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
