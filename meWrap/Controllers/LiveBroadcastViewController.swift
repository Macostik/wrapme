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
        let layer = streamer.startVideoCaptureWithCamera(cameraInfo.cameraID, orientation: .LandscapeRight, config: videoConfig, listener: self)
        layer.frame = view.bounds
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.insertSublayer(layer, atIndex: 0)
        streamer.startAudioCaptureWithConfig(audioConfig, listener: self)
    }
    
    func start() {
        let streamer = Streamer.instance() as! Streamer
        if let userUID = User.currentUser?.identifier, let deviceUID = Authorization.currentAuthorization.deviceUID {
            let uri = "rtsp://live.mewrap.me:1935/live/\(userUID)-\(deviceUID)"
            print(uri)
            connectionID = streamer.createConnectionWithListener(self, uri: uri, mode: 0)
        }
        
    }
    
    func stop() {
        if let connectionID = connectionID {
            self.connectionID = nil
            let streamer = Streamer.instance() as! Streamer
            streamer.releaseConnectionId(connectionID)
        }
    }
    
    @IBAction func startBroadcast(sender: UIButton) {
        if composeBar.text.characters.count == 0 {
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
