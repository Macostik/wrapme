//
//  LiveBroadcastPlayerViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

class LiveViewerViewController: LiveViewController {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private weak var playerLayer: AVPlayerLayer?
    
    private var playerItem: AVPlayerItem?
    
    deinit {
        guard let item = playerItem else { return }
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        
        let broadcast = self.broadcast
        
        guard let url = "http://live.mewrap.me:1935/live/\(broadcast.streamName)/playlist.m3u8".URL else { return }
        
        let layer = AVPlayerLayer()
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, atIndex: 0)
        playerLayer = layer
        
        let playerItem = AVPlayerItem(URL: url)
        playerItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
        let player = AVPlayer(playerItem: playerItem)
        layer.player = player
        self.playerItem = playerItem
        
        subscribe(broadcast)
        
        updateBroadcastInfo()
        
        Dispatch.mainQueue.after(0.5) { [weak self] () -> Void in
            PubNub.sharedInstance.hereNowForChannel("ch-\(broadcast.streamName)", withVerbosity: .UUID) { (result, status) -> Void in
                if let uuids = result?.data?.uuids as? [String] {
                    var viewers = Set<User>()
                    for uuid in uuids {
                        guard let user = PubNub.userFromUUID(uuid) else { return }
                        user.fetchIfNeeded(nil, failure: nil)
                        if user != broadcast.broadcaster {
                            viewers.insert(user)
                        }
                    }
                    if let user = User.currentUser where !viewers.contains(user) {
                        viewers.insert(user)
                    }
                    broadcast.viewers = viewers
                    self?.updateBroadcastInfo()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation { [unowned self] () -> Void in
            self.playerLayer?.frame = self.view.bounds
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let keyPath = keyPath, let item = playerItem else { return }
        if item.playbackLikelyToKeepUp {
            spinner.stopAnimating()
        } else {
            spinner.startAnimating()
        }
        switch keyPath {
        case "status" where item.status == .ReadyToPlay, "playbackLikelyToKeepUp" where item.playbackLikelyToKeepUp == true:
            playerLayer?.player?.play()
        default: break
        }
    }
    
    @IBAction func sendMessage(sender: AnyObject?) {
        if let text = composeBar.text, let uuid = User.currentUser?.uid where !text.isEmpty {
            chatSubscription?.send([
                "content" : text,
                "userUid" : uuid
                ])
        }
        composeBar.text = nil
    }
    
    override func wrapLiveBroadcastsUpdated() {
        if let wrap = wrap where !wrap.liveBroadcasts.contains(broadcast) {
            navigationController?.popViewControllerAnimated(false)
            Toast.show(String(format:"formatted_broadcast_end".ls, broadcast.broadcaster?.name ?? ""))
        }
    }
}
