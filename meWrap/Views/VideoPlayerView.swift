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
        path.move(0 ^ bounds.height / 2).line(bounds.width ^ bounds.height / 2).stroke()
        UIColor.whiteColor().setStroke()
        path.removeAllPoints()
        if time > 0 {
            let position = (bounds.width - path.lineWidth) * CGFloat(time)
            path.move(0 ^ bounds.height / 2).line(position ^ bounds.height / 2).stroke()
            path.removeAllPoints()
            path.move(position + path.lineWidth/2 ^ 0).line(position + path.lineWidth/2 ^ bounds.height).stroke()
        } else {
            path.move(path.lineWidth/2 ^ 0).line(path.lineWidth/2 ^ bounds.height).stroke()
        }
    }
}

class VideoPlayer: UIView {
    
    var didPlayToEnd: (() -> ())?
    var didPlay: (() -> ())?
    var didPause: (() -> ())?
    var didSeekToTime: (() -> ())?
    var didChangeStatus: (AVPlayerStatus -> ())?
    var playbackLikelyToKeepUp: (Bool -> ())?
    
    override class func layerClass() -> AnyClass  {
        return AVPlayerLayer.self
    }
    
    deinit {
        player.removeObserver(self, forKeyPath: "status")
        _item?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    var playing: Bool = false {
        didSet {
            guard playing != oldValue else { return }
            didChangePlaying(playing)
        }
    }
    
    internal func didChangePlaying(playing: Bool) {
        if playing {
            if let item = item where CMTimeCompare(item.currentTime(), item.duration) == 0 {
                item.seekToTime(kCMTimeZero)
            }
            player.play()
            didPlay?()
        } else {
            player.pause()
            didPause?()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let item = item else { return }
        if keyPath == "status" {
            didChangeStatus?(player.status)
            didChangeStatus(player.status)
        } else if keyPath == "playbackLikelyToKeepUp" {
            playbackLikelyToKeepUp?(item.playbackLikelyToKeepUp)
            didChangePlaybackLikelyToKeepUp(item.playbackLikelyToKeepUp)
        }
    }
    
    internal func didChangePlaybackLikelyToKeepUp(playbackLikelyToKeepUp: Bool) {}
    internal func didChangeStatus(status: AVPlayerStatus) {}
    
    private var _item: AVPlayerItem? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            _item?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
            player.replaceCurrentItemWithPlayerItem(_item)
        }
    }
    
    internal func didSetItem(item: AVPlayerItem?) {}
    
    var item: AVPlayerItem? {
        if _item == nil, let url = url {
            _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            _ = try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeMoviePlayback)
            _ = try? AVAudioSession.sharedInstance().setActive(true)
            _item = AVPlayerItem(URL: url)
        }
        return _item
    }
    
    lazy var player: AVPlayer = specify(AVPlayer()) { player in
        player.addObserver(self, forKeyPath: "status", options: .New, context: nil)
        (self.layer as? AVPlayerLayer)?.player = player
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.playerItemDidPlayToEndTime(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    var url: NSURL? {
        didSet {
            if url != oldValue {
                playing = false
                if _item != nil {
                    _item = nil
                }
                didSetURL(url)
            }
        }
    }
    
    internal func didSetURL(url: NSURL?) {}
    
    func playerItemDidPlayToEndTime(notification: NSNotification) {
        if _item == notification.object as? AVPlayerItem {
            playing = false
            didPlayToEnd?()
        }
    }
}

class VideoPlayerView: VideoPlayer {
    
    deinit {
        stopObservingTime(player)
    }
    
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
    
    override func awakeFromNib() {
        super.awakeFromNib()
        timeView?.userInteractionEnabled = false
        startObservingTime(player)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap(_:))))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    @IBOutlet weak var delegate: VideoPlayerViewDelegate?
    
    @IBOutlet weak var playButton: UIButton?
    
    @IBOutlet weak var timeView: VideoTimeView?
    
    override func didChangePlaying(playing: Bool) {
        super.didChangePlaying(playing)
        playButton?.selected = playing
    }
    
    weak var spinner: UIActivityIndicatorView?
    
    override func didChangeStatus(status: AVPlayerStatus) {
        if player.status == .ReadyToPlay {
            spinner?.stopAnimating()
        }
    }
    
    override func didChangePlaybackLikelyToKeepUp(playbackLikelyToKeepUp: Bool) {
        if playbackLikelyToKeepUp {
            if playing && self.seeking == false {
                player.play()
            }
            spinner?.stopAnimating()
        } else {
            spinner?.startAnimating()
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
                playerView.timeView?.time = CMTimeGetSeconds(item.currentTime()) / CMTimeGetSeconds(item.duration)
            }
        }
    }
    
    override func didSetItem(item: AVPlayerItem?) {
        timeView?.time = 0
        playButton?.selected = false
        spinner?.stopAnimating()
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
    
    var seeking: Bool {
        return panGestureRecognizer.state == .Changed
    }
    
    private func seekToTimeAtPoint(point: CGPoint) {
        guard let item = _item, let timeView = timeView else { return }
        let x = min(timeView.bounds.width, max(0, point.x))
        let ratio = Float64(x / timeView.bounds.width)
        timeView.time = ratio
        let duration = CMTimeGetSeconds(item.duration)
        let resultTime = CMTimeMakeWithSeconds(duration * ratio, Int32(NSEC_PER_SEC))
        player.seekToTime(resultTime)
        delegate?.videoPlayerViewSeekedToTime?(self)
    }
    
    private func shouldSeekToTimeAtPoint(point: CGPoint) -> Bool {
        guard let timeView = timeView else { return false }
        return CGRectInset(timeView.bounds, -6, -22).contains(point) && playing
    }
    
    func tap(sender: UITapGestureRecognizer) {
        self.superview?.endEditing(true)
        let location = sender.locationInView(timeView)
        if let timeView = timeView where shouldSeekToTimeAtPoint(location) && !timeView.hidden {
            seekToTimeAtPoint(location)
        } else {
            if let url = url where url.fileURL || Network.sharedNetwork.reachable {
                toggle()
            } else {
                InfoToast.show("no_internet_connection".ls)
            }
        }
    }
    
    func pan(sender: UIPanGestureRecognizer) {
        if let timeView = timeView where !timeView.hidden {
            let location = sender.locationInView(timeView)
            switch sender.state {
            case .Began:
                player.pause()
                seekToTimeAtPoint(location)
            case .Changed where seeking:
                seekToTimeAtPoint(location)
            case .Ended, .Cancelled, .Failed:
                if playing {
                    player.play()
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
