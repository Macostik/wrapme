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
    
    init(value: Key -> Value) {
        self.value = value
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.memoryWarning), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
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
        values.removeAll()
    }
}

final class VideoPlayer: UIView {
    
    private static let cache = InMemoryCache<NSURL, AVAsset>(value: { AVURLAsset(URL: $0) })
    
    lazy var volumeButton: Button = specify(Button.expandableCandyAction("l")) {
        $0.setTitle("m", forState: .Selected)
        $0.addTarget(self, touchUpInside: #selector(self.volume(_:)))
        $0.backgroundColor = UIColor(white: 0, alpha: 0.8)
    }
    
    lazy var spinner: UIActivityIndicatorView = specify(UIActivityIndicatorView(activityIndicatorStyle: .White)) {
        self.add($0) { $0.center.equalTo(self) }
    }
    
    private var paused = false
    
    static let didBecomeUnmuted = BlockNotifier<VideoPlayer>()
    
    static let pauseAll = BlockNotifier<Void>()
    
    static let resumeAll = BlockNotifier<Void>()
    
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
        }
        
        VideoPlayer.resumeAll.subscribe(self) { [unowned self] (value) in
            self.paused = false
            if self.playing && self.window != nil {
                self.player.play()
            }
        }
        
        VideoPlayer.didBecomeUnmuted.subscribe(self) { [unowned self] videoPlayer in
            if videoPlayer != self {
                self.muted = true
            }
        }
    }
    
    override class func layerClass() -> AnyClass  {
        return AVPlayerLayer.self
    }
    
    deinit {
        _item?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    var playing: Bool = false {
        didSet {
            guard playing != oldValue else { return }
            if playing {
                if !paused {
                    play()
                }
            } else {
                player.pause()
            }
        }
    }
    
    private func play() {
        if let item = item where CMTimeCompare(item.currentTime(), item.duration) == 0 {
            item.seekToTime(kCMTimeZero)
        }
        player.play()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let item = item else { return }
        if item.playbackLikelyToKeepUp {
            spinner.stopAnimating()
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
            AudioSession.mode = AVAudioSessionModeMoviePlayback
            AudioSession.category = AVAudioSessionCategoryAmbient
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
        if _item == notification.object as? AVPlayerItem && !paused {
            play()
        }
    }
    
    var muted: Bool {
        set {
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
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            player.pause()
        } else if playing && !paused {
            player.play()
        }
    }
}
