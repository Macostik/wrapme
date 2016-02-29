//
//  VideoPlayerView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

@objc protocol VideoPlayerViewDelegate: NSObjectProtocol {
    
    optional func videoPlayerViewDidBecomeReadyToPlay(view: VideoPlayerView)
    
    optional func videoPlayerViewDidPlayToEnd(view: VideoPlayerView)
    
    optional func videoPlayerViewDidPlay(view: VideoPlayerView)
    
    optional func videoPlayerViewDidPause(view: VideoPlayerView)
    
    optional func videoPlayerViewSeekedToTime(view: VideoPlayerView)
}

class VideoTimeView: UIView {
    
    var time: Float64 = 0 {
        didSet { setNeedsDisplay() }
    }
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = 2
        UIColor.whiteColor().colorWithAlphaComponent(0.5).setStroke()
        path.move(0, bounds.height / 2).line(bounds.width, bounds.height / 2).stroke()
        UIColor.whiteColor().setStroke()
        path.removeAllPoints()
        if time > 0 {
            let position = (bounds.width - path.lineWidth) * CGFloat(time)
            path.move(0, bounds.height / 2).line(position, bounds.height / 2).stroke()
            path.removeAllPoints()
            path.move(position + path.lineWidth/2, 0).line(position + path.lineWidth/2, bounds.height).stroke()
        } else {
            path.move(path.lineWidth/2, 0).line(path.lineWidth/2, bounds.height).stroke()
        }
    }
}

class VideoPlayerView: UIView {
    
    override class func layerClass() -> AnyClass  {
        return AVPlayerLayer.self
    }
    
    deinit {
        stopObservingTime(player)
        player.removeObserver(self, forKeyPath: "status")
        _item?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "pan:")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let playButtonView = placeholderPlayButton {
            let label = UILabel(frame: playButtonView.bounds)
            label.font = UIFont(name: "icons", size: 65)
            label.text = "."
            label.textAlignment = .Center
            if let blurEffect = playButtonView.effect as? UIBlurEffect {
                let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
                let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
                vibrancyEffectView.frame = playButtonView.bounds
                vibrancyEffectView.contentView.addSubview(label)
                playButtonView.contentView.addSubview(vibrancyEffectView)
            }
            playButtonView.layer.masksToBounds = true
            playButtonView.layer.mask = label.layer
        }
        timeView.userInteractionEnabled = false
        player.addObserver(self, forKeyPath: "status", options: .New, context: nil)
        startObservingTime(player)
        (layer as? AVPlayerLayer)?.player = player
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tap:"))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    @IBOutlet weak var delegate: VideoPlayerViewDelegate?
    
    @IBOutlet weak var secondaryPlayButton: UIButton? 
    
    @IBOutlet weak var playButton: UIView? 
    
    @IBOutlet weak var placeholderPlayButton: UIVisualEffectView?
    
    @IBOutlet weak var timeView: VideoTimeView!
    
    @IBOutlet weak var timeViewPrioritizer: LayoutPrioritizer?
    
    var playing: Bool = false {
        didSet {
            guard playing != oldValue else { return }
            if playing {
                
                if let item = item where CMTimeCompare(item.currentTime(), item.duration) == 0 {
                    item.seekToTime(kCMTimeZero)
                }
                player.play()
                if player.status != .ReadyToPlay {
                    spinner?.startAnimating()
                }
                delegate?.videoPlayerViewDidPlay?(self)
            } else {
                player.pause()
                delegate?.videoPlayerViewDidPause?(self)
                
            }
            hiddenCenterViews(true)
            hiddenBottomViews(false)
            
            secondaryPlayButton?.selected = playing
        }
    }
    
    func hiddenCenterViews (hidden: Bool) {
        placeholderPlayButton?.hidden = hidden
        playButton?.hidden = hidden
    }
    
    func hiddenBottomViews (hidden: Bool) {
        secondaryPlayButton?.hidden = hidden
        timeView.hidden = hidden
        secondaryPlayButton?.addAnimation(CATransition.transition(kCATransitionFade))
        timeView?.addAnimation(CATransition.transition(kCATransitionFade))
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let item = item else {
            return
        }
        if keyPath == "status" {
            if player.status == .ReadyToPlay {
                spinner?.stopAnimating()
            }
        } else if keyPath == "playbackLikelyToKeepUp" {
            if item.playbackLikelyToKeepUp {
                if playing && self.seeking == false {
                    player.play()
                }
                spinner?.stopAnimating()
            } else {
                spinner?.startAnimating()
            }
        }
    }
    
    private weak var timeObserver: AnyObject?
    
    func stopObservingTime(player: AVPlayer) {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    func startObservingTime(player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.01, Int32(NSEC_PER_SEC)), queue: dispatch_get_main_queue()) {[weak self] (time) -> Void in
            if let playerView = self, let item = playerView.item where playerView.seeking == false {
                playerView.timeView.time = CMTimeGetSeconds(item.currentTime()) / CMTimeGetSeconds(item.duration)
            }
        }
    }
    
    private var _item: AVPlayerItem? {
        didSet {
            if let oldItem = oldValue {
                oldItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            }
            if let item = _item {
                item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
            }
            player.replaceCurrentItemWithPlayerItem(_item)
            timeView.time = 0
            secondaryPlayButton?.selected = false
            spinner?.stopAnimating()
        }
    }
    
    var item: AVPlayerItem? {
        get {
            if _item == nil, let url = url {
                _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                _ = try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeMoviePlayback)
                _ = try? AVAudioSession.sharedInstance().setActive(true)
                _item = AVPlayerItem(URL: url)
            }
            return _item
        }
    }
    
    var player: AVPlayer = AVPlayer()
    
    var url: NSURL? {
        didSet {
            if url != oldValue {
                playing = false
                if _item != nil {
                    _item = nil
                }
                seeking = false
            }
        }
    }
    
    func playerItemDidPlayToEndTime(notification: NSNotification) {
        if _item == notification.object as? AVPlayerItem {
            playing = false
            hiddenCenterViews(false)
            hiddenBottomViews(true)
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
        guard let item = _item else {
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
        return CGRectContainsPoint(CGRectInset(timeView.bounds, -6, -22), point) && playing
    }
    
    func tap(sender: UITapGestureRecognizer) {
        self.superview!.endEditing(true)
        let location = sender.locationInView(timeView)
        if shouldSeekToTimeAtPoint(location) && !timeView.hidden {
            seekToTimeAtPoint(location)
        } else {
            if let url = url where url.fileURL || Network.sharedNetwork.reachable {
                toggle()
            } else {
                Toast.show("no_internet_connection".ls)
            }
        }
    }
    
    func pan(sender: UIPanGestureRecognizer) {
        if (!timeView.hidden) {
            let location = sender.locationInView(timeView)
            switch sender.state {
            case .Began:
                seeking = true
                player.pause()
                seekToTimeAtPoint(location)
            case .Changed:
                if seeking {
                    seekToTimeAtPoint(location)
                }
            case .Ended:
                if seeking {
                    seeking = false
                    if playing {
                        player.play()
                    }
                } else {
                    toggle()
                }
            case .Cancelled, .Failed:
                if seeking {
                    seeking = false
                    if playing {
                        player.play()
                    }
                }
            default: break
            }
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
