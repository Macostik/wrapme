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

final class VideoPlayer: UIView {
    
    lazy var volumeButton: Button = specify(Button.expandableCandyAction("l")) {
        $0.setTitle("m", forState: .Selected)
        $0.addTarget(self, touchUpInside: #selector(self.volume(_:)))
        $0.backgroundColor = UIColor(white: 0, alpha: 0.8)
    }
    
    lazy var spinner: UIActivityIndicatorView = specify(UIActivityIndicatorView(activityIndicatorStyle: .White)) {
        self.add($0) { $0.center.equalTo(self) }
    }
    
    static let notifier = BlockNotifier<VideoPlayer>()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        VideoPlayer.notifier.subscribe(self) { (owner, videoPlayer) in
            if videoPlayer != owner {
                owner.muted = true
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
                play()
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
            _item = AVPlayerItem(URL: url)
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
            play()
        }
    }
    
    var muted: Bool {
        set {
            player.muted = newValue
            volumeButton.selected = !newValue
            if newValue == false {
                VideoPlayer.notifier.notify(self)
            }
        }
        get {
            return player.muted
        }
    }
    
    @objc private func volume(sender: UIButton) {
        muted = !muted
    }
}
