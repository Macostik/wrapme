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
        
        showCoverViewWithText("loading...".ls)
        
        if let wrap = wrap {
            PubNub.sharedInstance.hereNowForChannel(wrap.uid, withVerbosity: .State, completion: { [weak self] (result, status) -> Void in
                guard let broadcast = self?.broadcast else { return }
                if let uuids = result?.data?.uuids as? [[String:AnyObject]] {
                    for uuid in uuids {
                        guard let activity = uuid["state"]?["activity"] as? [String:AnyObject] else { continue }
                        guard activity["type"] as? Int == UserActivityType.Streaming.rawValue else { continue }
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
        showCoverViewWithText("broadcast_end".ls)
    }
    
    private func showCoverViewWithText(text: String) {

        self.coverView?.removeFromSuperview()
        
        let coverView = UIView()
        coverView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(coverView, belowSubview: spinner)
        self.coverView = coverView
        
        let coverImageView = ImageView()
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.backgroundColor = UIColor.blackColor()
        coverImageView.contentMode = .ScaleAspectFill
        coverImageView.clipsToBounds = true
        coverView.addSubview(coverImageView)
        
        let blurEffect = UIBlurEffect(style: .Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        coverView.addSubview(blurView)
        
        let wrapNameLabel = Label()
        wrapNameLabel.translatesAutoresizingMaskIntoConstraints = false
        wrapNameLabel.font = UIFont.fontXLarge()
        wrapNameLabel.preset = FontPreset.XLarge.rawValue
        wrapNameLabel.textColor = UIColor.whiteColor()
        wrapNameLabel.text = wrap?.name
        coverView.addSubview(wrapNameLabel)
        
        let titleLabel = Label()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.lightFontLarger()
        titleLabel.preset = FontPreset.Larger.rawValue
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.text = broadcast.displayTitle()
        coverView.addSubview(titleLabel)
        
        let messageLabel = Label()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.lightFontNormal()
        messageLabel.preset = FontPreset.Normal.rawValue
        messageLabel.textColor = UIColor.whiteColor()
        messageLabel.text = text
        coverView.addSubview(messageLabel)
        
        let backButton = Button()
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.titleLabel?.font = UIFont(name: "icons", size: 36)
        backButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        backButton.setTitleColor(UIColor.whiteColor().darkerColor(), forState: .Normal)
        backButton.setTitle("w", forState: .Normal)
        backButton.addTarget(self, action: "close:", forControlEvents: .TouchUpInside)
        coverView.addSubview(backButton)
        
        view.makeResizibleSubview(coverView)
        coverView.makeResizibleSubview(coverImageView)
        coverView.makeResizibleSubview(blurView)
        
        coverView.addConstraint(NSLayoutConstraint(item: wrapNameLabel, attribute: .CenterY, relatedBy: .Equal, toItem: coverView, attribute: .CenterY, multiplier: 1, constant: -100))
        coverView.addConstraint(NSLayoutConstraint(item: wrapNameLabel, attribute: .CenterX, relatedBy: .Equal, toItem: coverView, attribute: .CenterX, multiplier: 1, constant: 0))
        
        coverView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .Top, relatedBy: .Equal, toItem: wrapNameLabel, attribute: .Bottom, multiplier: 1, constant: 0))
        coverView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .CenterX, relatedBy: .Equal, toItem: coverView, attribute: .CenterX, multiplier: 1, constant: 0))
        
        coverView.addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .CenterY, relatedBy: .Equal, toItem: coverView, attribute: .CenterY, multiplier: 1, constant: 80))
        coverView.addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .CenterX, relatedBy: .Equal, toItem: coverView, attribute: .CenterX, multiplier: 1, constant: 0))
        
        coverView.addConstraint(NSLayoutConstraint(item: backButton, attribute: .Leading, relatedBy: .Equal, toItem: coverView, attribute: .Leading, multiplier: 1, constant: 12))
        coverView.addConstraint(NSLayoutConstraint(item: backButton, attribute: .Top, relatedBy: .Equal, toItem: coverView, attribute: .Top, multiplier: 1, constant: 12))
        
        coverImageView.url = broadcast.broadcaster?.avatar?.large
        
        self.coverView = coverView
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
            removeCoverViewIfNeeded()
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
            unsubscribeObserving()
            playerLayer?.player?.pause()
            spinner.stopAnimating()
            showEndBroadcast()
        }
    }
}
