//
//  LiveBroadcastPlayerViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import PubNub
import SnapKit

class LiveViewerViewController: LiveViewController {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private var playerLayer = AVPlayerLayer()
    
    private var playerItem: AVPlayerItem?
    
    private weak var coverView: UIView?
    
    private weak var coverLabel: UIView?
    
    private var broadcastExists = false
    
    deinit {
        unsubscribeObserving()
    }
    
    private func unsubscribeObserving() {
        guard let item = playerItem else { return }
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        playerItem = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        _ = try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeMoviePlayback)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        
        let broadcast = self.broadcast
        
        guard let url = "http://live.mewrap.me:1935/live/\(broadcast.streamName)/playlist.m3u8".URL else { return }
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        playerLayer.frame = view.bounds
        view.layer.insertSublayer(playerLayer, atIndex: 0)
        
        let playerItem = AVPlayerItem(URL: url)
        playerItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
        let player = AVPlayer(playerItem: playerItem)
        playerLayer.player = player
        self.playerItem = playerItem
        
        chatSubscription.subscribe()
        
        updateBroadcastInfo()
        
        Dispatch.mainQueue.after(0.5) { [weak self] () -> Void in
            PubNub.sharedInstance.hereNowForChannel("ch-\(broadcast.streamName)", withVerbosity: .UUID) { (result, status) -> Void in
                if let uuids = result?.data.uuids as? [String] {
                    var viewers = Set<User>()
                    for uuid in uuids {
                        if uuid != User.uuid() {
                            guard let user = PubNub.userFromUUID(uuid) else { return }
                            user.fetchIfNeeded(nil, failure: nil)
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
        
        showCoverViewWithText("loading...".ls)
        
        if let wrap = wrap {
            PubNub.sharedInstance.hereNowForChannel(wrap.uid, withVerbosity: .State, completion: { [weak self] (result, status) -> Void in
                guard let broadcast = self?.broadcast else { return }
                if let uuids = result?.data.uuids as? [[String:AnyObject]] {
                    for uuid in uuids {
                        guard let activity = uuid["state"]?["activity"] as? [String:AnyObject] else { continue }
                        guard activity["type"] as? Int == UserActivityType.Live.rawValue else { continue }
                        guard let streamName = activity["streamName"] as? String else { continue }
                        if streamName == broadcast.streamName {
                            self?.broadcastExists = true
                            self?.removeCoverViewIfNeeded()
                            return
                        }
                    }
                }
                self?.wrap?.removeBroadcast(broadcast)
                self?.showEndBroadcast()
            })
        }
    }
    
    private func removeCoverViewIfNeeded() {
        if broadcastExists && !spinner.isAnimating() {
            coverView?.removeFromSuperview()
        }
    }
    
    private func showEndBroadcast() {
        view.endEditing(true)
        showCoverViewWithText("broadcast_end".ls)
    }
    
    private func showCoverViewWithText(text: String) {

        self.coverView?.removeFromSuperview()
        
        let coverView = UIView()
        view.insertSubview(coverView, belowSubview: spinner)
        self.coverView = coverView
        
        let coverImageView = ImageView(backgroundColor: UIColor.blackColor())
        coverView.addSubview(coverImageView)
        
        let blurEffect = UIBlurEffect(style: .Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        coverView.addSubview(blurView)
        
        let wrapNameLabel = Label(preset: .XLarge, weight: .Regular, textColor: UIColor.whiteColor())
        wrapNameLabel.text = wrap?.name
        coverView.addSubview(wrapNameLabel)
        
        let titleLabel = Label(preset: .Larger, textColor: UIColor.whiteColor())
        titleLabel.text = broadcast.displayTitle()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Center
        coverView.addSubview(titleLabel)
        
        let messageLabel = Label(preset: .Normal, textColor: UIColor.whiteColor())
        messageLabel.text = text
        coverView.addSubview(messageLabel)
        
        let backButton = Button()
        backButton.titleLabel?.font = UIFont(name: "icons", size: 36)
        backButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        backButton.setTitleColor(UIColor.whiteColor().darkerColor(), forState: .Normal)
        backButton.setTitle("w", forState: .Normal)
        backButton.addTarget(self, action: #selector(LiveViewController.close(_:)), forControlEvents: .TouchUpInside)
        coverView.addSubview(backButton)
        
        coverView.snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        coverImageView.snp_makeConstraints(closure: { $0.edges.equalTo(coverView) })
        blurView.snp_makeConstraints(closure: { $0.edges.equalTo(coverView) })
        
        wrapNameLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(coverView).inset(-100)
            make.centerX.equalTo(coverView)
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(wrapNameLabel.snp_bottom)
            make.leading.trailing.equalTo(coverView).inset(12)
        }
        
        messageLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(coverView).inset(80)
            make.centerX.equalTo(coverView)
        }
        
        backButton.snp_makeConstraints { $0.leading.top.equalTo(coverView).inset(12) }
        
        if let user = broadcast.broadcaster {
            if let url = user.avatar?.large where !url.isEmpty {
                coverImageView.url = url
            } else {
                user.fetch({ (_) -> Void in
                    coverImageView.url = user.avatar?.large
                    }, failure: nil)
            }
        }
        
        self.coverView = coverView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation { self.playerLayer.frame = self.view.bounds }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let keyPath = keyPath, let item = playerItem else { return }
        if item.playbackLikelyToKeepUp {
            spinner.stopAnimating()
            removeCoverViewIfNeeded()
        } else {
            spinner.startAnimating()
        }
        switch keyPath {
        case "status" where item.status == .ReadyToPlay, "playbackLikelyToKeepUp" where item.playbackLikelyToKeepUp == true:
            playerLayer.player?.play()
        default: break
        }
    }
    
    @IBAction func sendMessage(sender: AnyObject?) {
        if let text = composeBar.text?.trim where !text.isEmpty {
            chatSubscription.send([
                "content" : text,
                "userUid" : User.currentUser?.uid ?? ""
                ])
        }
        composeBar.text = nil
    }
    
    override func wrapLiveBroadcastsUpdated() {
        if let wrap = wrap where !wrap.liveBroadcasts.contains(broadcast) {
            unsubscribeObserving()
            playerLayer.player?.pause()
            spinner.stopAnimating()
            showEndBroadcast()
        }
    }
}
