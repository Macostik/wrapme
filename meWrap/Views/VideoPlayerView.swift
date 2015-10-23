//
//  VideoPlayerView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import AVFoundation

@objc protocol VideoPlayerViewDelegate: NSObjectProtocol {
    
    optional func videoPlayerViewDidBecomeReadyToPlay(view: VideoPlayerView)
    
    optional func videoPlayerViewDidPlayToEnd(view: VideoPlayerView)
    
    optional func videoPlayerViewDidPlay(view: VideoPlayerView)
    
    optional func videoPlayerViewDidPause(view: VideoPlayerView)
    
    optional func videoPlayerViewSeekedToTime(view: VideoPlayerView)
}

class VideoTimeView: UIView {
    
    var time: Float64 = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        
        let path = UIBezierPath()
        path.lineWidth = 2
        path.moveToPoint(CGPoint(x: 0, y: bounds.height / 2))
        path.addLineToPoint(CGPoint(x: bounds.width, y: bounds.height / 2))
        UIColor.whiteColor().colorWithAlphaComponent(0.5).setStroke()
        path.stroke()
        
        UIColor.whiteColor().setStroke()
        
        if time > 0 {
            let position = (bounds.width - path.lineWidth) * CGFloat(time)
            path.removeAllPoints()
            path.moveToPoint(CGPoint(x: 0, y: bounds.height / 2))
            path.addLineToPoint(CGPoint(x: position, y: bounds.height / 2))
            path.stroke()
            
            path.removeAllPoints()
            path.moveToPoint(CGPoint(x: position + path.lineWidth/2, y: 0))
            path.addLineToPoint(CGPoint(x: position + path.lineWidth/2, y: bounds.height))
            path.stroke()
            
        } else {
            
            path.removeAllPoints()
            path.moveToPoint(CGPoint(x: path.lineWidth/2, y: 0))
            path.addLineToPoint(CGPoint(x: path.lineWidth/2, y: bounds.height))
            path.stroke()
        }
    }
}

class VideoPlayerView: UIView {
    override class func layerClass() -> AnyClass  {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        awake()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        awake()
    }
    
    deinit {
        if let player = _player {
            finalizePlayer(player)
        }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    func awake() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tap:"))
        let recognizer = UIPanGestureRecognizer(target: self, action: "pan:")
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
        panGestureRecognizer = recognizer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    @IBOutlet weak var delegate: VideoPlayerViewDelegate?
    
    @IBOutlet weak var playButton: UIButton?
    
    @IBOutlet weak var timeView: VideoTimeView! {
        didSet {
            timeView.userInteractionEnabled = false
        }
    }
    
    private var _playing = false
    var playing: Bool {
        set {
            if let player = player {
                if _playing != newValue {
                    _playing = newValue
                    
                    if newValue {
                        startObservingTime(player)
                        if let item = player.currentItem {
                            if CMTimeCompare(item.currentTime(), item.duration) == 0 {
                                item.seekToTime(kCMTimeZero)
                            }
                        }
                        player.play()
                        if player.status != .ReadyToPlay {
                            spinner?.startAnimating()
                        }
                        delegate?.videoPlayerViewDidPlay?(self)
                    } else {
                        stopObservingTime(player)
                        player.pause()
                        delegate?.videoPlayerViewDidPause?(self)
                    }
                    
                    playButton?.selected = newValue
                }
            }
        }
        get {
            return _playing
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let player = player, let item = player.currentItem else {
            return
        }
        if keyPath == "status" {
            if player.status == .ReadyToPlay {
                spinner?.stopAnimating()
            }
        } else if keyPath == "playbackLikelyToKeepUp" {
            if item.playbackLikelyToKeepUp {
                if _playing && self.seeking == false {
                    player.play()
                }
                spinner?.stopAnimating()
            } else {
                spinner?.startAnimating()
            }
        }
    }
    
    private func finalizePlayer(player: AVPlayer) {
        player.removeObserver(self, forKeyPath: "status")
        player.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        stopObservingTime(player)
    }
    
    private var _player: AVPlayer? {
        didSet {
            if let oldValue = oldValue {
                finalizePlayer(oldValue)
            }
            
            if let player = _player {
                player.addObserver(self, forKeyPath: "status", options: .New, context: nil)
                player.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
            }
            
            (layer as? AVPlayerLayer)?.player = _player
            
            timeView.time = 0
            
            playButton?.selected = false
        }
    }
    
    func stopObservingTime(player: AVPlayer) {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    func startObservingTime(player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.01, Int32(NSEC_PER_SEC)), queue: dispatch_get_main_queue()) {[unowned self] (time) -> Void in
            if let item = self.player?.currentItem where self.seeking == false {
                self.timeView.time = CMTimeGetSeconds(item.currentTime()) / CMTimeGetSeconds(item.duration)
            }
        }
    }
    
    var player: AVPlayer? {
        get {
            if _player == nil, let url = url {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                }
                _player = AVPlayer(URL: url)
            }
            return _player
        }
    }
    
    private weak var timeObserver: AnyObject?
    
    var url: NSURL? {
        didSet {
            if _playing {
                playing = false
            }
            if _player != nil {
                _player = nil
            }
            seeking = false
        }
    }
    
    func playerItemDidPlayToEndTime(notification: NSNotification) {
        if player?.currentItem == notification.object as? AVPlayerItem {
            playing = false
            delegate?.videoPlayerViewDidPlayToEnd?(self)
        }
    }
    
    @IBAction func play() {
        playing = true
    }
    
    @IBAction func pause() {
        playing = false
    }
    
    @IBAction func toggle() {
        playing = !playing
    }
    
    // MARK: - VideoTimeViewDelegate
    
    var seeking = false
    
    private func seekToTimeAtPoint(point: CGPoint) {
        guard let player = player, let item = player.currentItem else {
            return
        }
        let x = min(timeView.bounds.width, max(0, point.x))
        let ratio = Float64(x / timeView.bounds.width)
        timeView.time = ratio
        let duration = CMTimeGetSeconds(item.duration)
        let resultTime = CMTimeMakeWithSeconds(duration * ratio, Int32(NSEC_PER_SEC))
        player.seekToTime(resultTime)
        delegate?.videoPlayerViewSeekedToTime?(self)
    }
    
    private func shouldSeekToTimeAtPoint(point: CGPoint) -> Bool {
        return CGRectContainsPoint(CGRectInset(timeView.bounds, -6, -22), point) && _playing
    }
    
    func tap(sender: UITapGestureRecognizer) {
        let location = sender.locationInView(timeView)
        if shouldSeekToTimeAtPoint(location) {
            seekToTimeAtPoint(location)
        } else {
            toggle()
        }
    }
    
    func pan(sender: UITapGestureRecognizer) {
        let location = sender.locationInView(timeView)
        switch sender.state {
        case .Began:
            seeking = true
            player?.pause()
            seekToTimeAtPoint(location)
        case .Changed:
            if seeking {
                seekToTimeAtPoint(location)
            }
        case .Ended:
            if seeking {
                seeking = false
                if _playing {
                    player?.play()
                }
            } else {
                toggle()
            }
        case .Cancelled, .Failed:
            if seeking {
                seeking = false
                if _playing {
                    player?.play()
                }
            }
        default: break
        }
    }
}

extension VideoPlayerView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            return shouldSeekToTimeAtPoint(gestureRecognizer.locationInView(timeView))
        } else {
            return true
        }
    }
}
