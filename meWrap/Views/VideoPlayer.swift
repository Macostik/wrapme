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

final class InMemoryCache<Key: Hashable, Value> {
    
    private var values = [Key: Value]()
    
    private let value: Key -> Value
    
    init(value: Key -> Value, clearOnMemoryWarning: Bool = true) {
        self.value = value
        if clearOnMemoryWarning {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.memoryWarning), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        }
    }
    
    subscript(key: Key) -> Value {
        if let value = values[key] {
            return value
        } else {
            let value = self.value(key)
            values[key] = value
            return value
        }
    }
    
    @objc private func memoryWarning() {
        clear()
    }
    
    func clear() {
        values.removeAll()
    }
}

private let maximumNumberOfReplays = 4

protocol VideoPlayerOwner: class {
    func videoPlayerDidChangeOwner()
}

final class VideoPlayer: UIView {
    
    weak static var owner: VideoPlayerOwner? {
        didSet {
            if owner !== oldValue {
                oldValue?.videoPlayerDidChangeOwner()
            }
        }
    }
    
    private static let cache = InMemoryCache<NSURL, AVAsset>(value: { AVURLAsset(URL: $0) })
    
    lazy var volumeButton: Button = specify(.expandableCandyAction("l")) {
        $0.setTitle("m", forState: .Selected)
        $0.addTarget(self, touchUpInside: #selector(self.volume(_:)))
        $0.backgroundColor = UIColor(white: 0, alpha: 0.8)
    }
    
    lazy var replayButton: Button = specify(Button(icon: ",", size: 24)) {
        $0.setTitleColor(Color.grayLight, forState: .Highlighted)
        $0.addTarget(self, touchUpInside: #selector(self.replay(_:)))
        $0.hidden = true
        $0.setTitleShadowColor(UIColor.blackColor(), forState: .Normal)
        $0.titleLabel?.layer.shadowOffset = 0 ^ 0
        $0.titleLabel?.layer.shadowOpacity = 0.75
    }
    
    lazy var spinner: UIActivityIndicatorView = specify(UIActivityIndicatorView(activityIndicatorStyle: .White)) {
        self.add($0) { $0.center.equalTo(self) }
    }
    
    private var paused = false
    
    static let didBecomeUnmuted = Notifier<VideoPlayer>()
    
    static let pauseAll = Notifier<Void>()
    
    static let resumeAll = Notifier<Void>()
    
    static func createPlayerView(muted: Bool = true) -> VideoPlayer {
        let playerView = VideoPlayer()
        (playerView.layer as? AVPlayerLayer)?.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerView.muted = muted
        return playerView
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
        VideoPlayer.pauseAll.subscribe(self) { [unowned self] (value) in
            self.paused = true
            self.player.pause()
            self._item = nil
        }
        
        VideoPlayer.resumeAll.subscribe(self) { [unowned self] (value) in
            self.paused = false
            if self.playing {
                self.play()
            }
        }
        
        VideoPlayer.didBecomeUnmuted.subscribe(self) { [unowned self] videoPlayer in
            if videoPlayer != self {
                self.muted = true
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.audioSessionInterruption(_:)), name: AVAudioSessionInterruptionNotification, object: nil)
    }
    
    func audioSessionInterruption(notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }
        let intValue: Int = info[AVAudioSessionInterruptionTypeKey] as? Int ?? 0
        if let type = AVAudioSessionInterruptionType(rawValue: UInt(intValue)) {
            switch type {
            case .Began:
                break
            case .Ended:
                if playing {
                    play()
                }
            }
        }
    }
    
    override class func layerClass() -> AnyClass  {
        return AVPlayerLayer.self
    }
    
    deinit {
        _item?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private var numberOfReplays = 0
    
    var playing: Bool = false {
        didSet {
            guard playing != oldValue else { return }
            numberOfReplays = 0
            if playing {
                play()
            } else {
                player.pause()
            }
        }
    }
    
    func startPlaying() {
        Dispatch.mainQueue.async { [weak self] () in
            self?.playing = true
        }
    }
    
    private func play() {
        guard !paused else { return }
        guard let item = item else { return }
        replayButton.hidden = true
        volumeButton.hidden = false
        if CMTimeCompare(item.currentTime(), item.duration) >= 0 {
            item.seekToTime(kCMTimeZero)
        }
        player.play()
        if !item.playbackLikelyToKeepUp {
            spinner.startAnimating()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let item = item else { return }
        if item.playbackLikelyToKeepUp {
            spinner.stopAnimating()
            if playing {
                play()
            }
        } else {
            spinner.startAnimating()
        }
    }
    
    private var _item: AVPlayerItem? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            _item?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
            player.replaceCurrentItemWithPlayerItem(_item)
        }
    }
    
    var item: AVPlayerItem? {
        if _item == nil, let url = url {
            _item = AVPlayerItem(asset: VideoPlayer.cache[url])
        }
        return _item
    }
    
    lazy var player: AVPlayer = specify(AVPlayer()) { player in
        player.muted = true
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
            }
        }
    }
    
    func playerItemDidPlayToEndTime(notification: NSNotification) {
        if _item == notification.object as? AVPlayerItem {
            numberOfReplays = numberOfReplays + 1
            if numberOfReplays == maximumNumberOfReplays {
                numberOfReplays = 0
                playing = false
                replayButton.hidden = false
                volumeButton.hidden = true
                if width >= Constants.screenWidth {
                    replayButton.titleLabel?.font = .icons(36)
                }
            } else {
                play()
            }
        }
    }
    
    var muted: Bool {
        set {
            if !newValue {
                AudioSession.mode = AVAudioSessionModeMoviePlayback
                AudioSession.category = AVAudioSessionCategoryAmbient
            }
            player.muted = newValue
            volumeButton.selected = !newValue
            if newValue == false {
                VideoPlayer.didBecomeUnmuted.notify(self)
            }
        }
        get {
            return player.muted
        }
    }
    
    @objc private func volume(sender: UIButton) {
        muted = !muted
    }
    
    @objc private func replay(sender: UIButton) {
        play()
    }
}
