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
