//
//  VideoPlayerView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import AVFoundation

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
    
    func awake() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggle"))
    }
    
    var player: AVPlayer?
    
    var playing = false {
        didSet {
            guard let player = player else {
                return
            }
            if playing {
                if let item = player.currentItem {
                    if CMTimeCompare(item.currentTime(), item.duration) == 0 {
                        item.seekToTime(kCMTimeZero)
                    }
                }
                player.play()
            } else {
                player.pause()
            }
        }
    }
    
    var url: NSURL? {
        didSet {
            guard let url = url else {
                return
            }
            player = AVPlayer(URL: url)
            guard let layer = layer as? AVPlayerLayer else {
                return
            }
            layer.player = player
        }
    }
    
    func play() {
        playing = true
    }
    
    func pause() {
        playing = false
    }
    
    func toggle() {
        playing = !playing
    }
}