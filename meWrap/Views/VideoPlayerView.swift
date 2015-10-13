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
}

protocol VideoTimeViewDelegate: NSObjectProtocol {
    func videoTimeView(view: VideoTimeView, didSeekToTime time: Float64)
}

class VideoTimeView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        awake()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        awake()
    }
    
    func awake() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tap:"))
    }
    
    weak var delegate: VideoTimeViewDelegate?
    
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
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let rect = CGRectInset(bounds, -6, -22)
        return CGRectContainsPoint(rect, point)
    }
    
    func tap(sender: UITapGestureRecognizer) {
        if let delegate = delegate {
            let x = min(bounds.width, max(0, sender.locationInView(self).x))
            let time = Float64(x / bounds.width)
            self.time = time
            delegate.videoTimeView(self, didSeekToTime: time)
        }
    }
}

class VideoPlayerView: UIView, VideoTimeViewDelegate {
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
    
    func awake() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggle"))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    @IBOutlet weak var delegate: VideoPlayerViewDelegate?
    
    @IBOutlet weak var playButton: UIButton?
    
    @IBOutlet weak var timeView: VideoTimeView! {
        didSet {
            if let timeView = timeView {
                timeView.delegate = self
            }
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
                        if let delegate = delegate {
                            delegate.videoPlayerViewDidPlay?(self)
                        }
                    } else {
                        stopObservingTime(player)
                        player.pause()
                        if let delegate = delegate {
                            delegate.videoPlayerViewDidPause?(self)
                        }
                    }
                    
                    if let playButton = playButton {
                        playButton.selected = newValue
                    }
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
                readyToPlay = true
            } else {
                readyToPlay = false
            }
        } else if keyPath == "playbackLikelyToKeepUp" {
            if item.playbackLikelyToKeepUp {
                if _playing {
                    player.play()
                }
                if let spinner = spinner {
                    spinner.stopAnimating()
                }
            } else {
                if let spinner = spinner {
                    spinner.startAnimating()
                }
            }
        }
    }
    
    var readyToPlay = false
    
    private func finalizePlayer(player: AVPlayer) {
        player.removeObserver(self, forKeyPath: "status")
        if let item = player.currentItem {
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        }
        stopObservingTime(player)
    }
    
    private var _player: AVPlayer? {
        didSet {
            if let oldValue = oldValue {
                finalizePlayer(oldValue)
            }
            
            if let player = _player {
                player.addObserver(self, forKeyPath: "status", options: .New, context: nil)
                if let item = player.currentItem {
                    item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
                }
            }
            
            if let layer = layer as? AVPlayerLayer {
                layer.player = _player
            }
            
            if let timeView = timeView {
                timeView.time = 0
            }
            
            if let playButton = playButton {
                playButton.selected = false
            }
        }
    }
    
    func stopObservingTime(player: AVPlayer) {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
    }
    
    func startObservingTime(player: AVPlayer) {
        
        unowned let weakSelf = self
        unowned let weakPlayer = player
        timeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.01, Int32(NSEC_PER_SEC)), queue: dispatch_get_main_queue()) {(time) -> Void in
            if let item = weakPlayer.currentItem, let timeView = weakSelf.timeView {
                timeView.time = CMTimeGetSeconds(item.currentTime()) / CMTimeGetSeconds(item.duration)
            }
        }
    }
    
    var player: AVPlayer? {
        get {
            if _player == nil, let url = url {
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
        }
    }
    
    func playerItemDidPlayToEndTime(notification: NSNotification) {
        if let player = player where player.currentItem == notification.object as? AVPlayerItem {
            
            playing = false
            
            if let delegate = delegate {
                delegate.videoPlayerViewDidPlayToEnd?(self)
            }
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
    
    func videoTimeView(view: VideoTimeView, didSeekToTime time: Float64) {
        if let player = player, let item = player.currentItem {
            let duration = CMTimeGetSeconds(item.duration)
            player.seekToTime(CMTimeMakeWithSeconds(duration * time, Int32(NSEC_PER_SEC)))
        }
    }
}