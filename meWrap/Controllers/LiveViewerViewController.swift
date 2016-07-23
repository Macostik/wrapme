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
import AVFoundation

class LiveViewerViewController: LiveViewController {
    
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
    
    private var playerLayer = AVPlayerLayer()
    
    private var playerItem: AVPlayerItem?
    
    private weak var coverView: UIView?
    
    private weak var coverLabel: UIView?
    
    private var broadcastExists = false
    
    deinit {
        unsubscribeObserving()
    }
    
    private func unsubscribeObserving() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if let item = playerItem {
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            playerItem = nil
        }
    }
    
    func applicationWillResignActive() {
        playerLayer.player?.pause()
    }
    
    func applicationDidBecomeActive() {
        playerLayer.player?.play()
    }
    
    override func loadView() {
        super.loadView()
        
        composeBar.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            let constraint = make.bottom.equalTo(view).constraint
            Keyboard.keyboard.handle(self, willShow: { [unowned self] (keyboard) in
                keyboard.performAnimation { () in
                    constraint.updateOffset(-keyboard.height)
                    self.view.layoutIfNeeded()
                }
            }) { [unowned self] (keyboard) in
                keyboard.performAnimation { () in
                    constraint.updateOffset(0)
                    self.view.layoutIfNeeded()
                }
            }
        }
        
        
        view.add(spinner) { (make) in
            make.center.equalTo(view)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        composeBar.textView.placeholder = "view_broadcast_text_placeholder".ls
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationWillResignActive), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        AudioSession.mode = AVAudioSessionModeMoviePlayback
        AudioSession.category = AVAudioSessionCategoryPlayback
        
        let broadcast = self.broadcast
        
        guard let url = "http://live.mewrap.me:1935/live/\(broadcast.streamName)/playlist.m3u8".URL else { return }
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        playerLayer.frame = view.bounds
        view.layer.insertSublayer(playerLayer, atIndex: 0)
        
        let playerItem = AVPlayerItem(URL: url)
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .New, context: nil)
        playerLayer.player = AVPlayer(playerItem: playerItem)
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
                        guard let activity = (uuid["state"] as? [String:AnyObject])?["activity"] as? [String:AnyObject] else { continue }
                        guard let type = activity["type"] else { continue }
                        guard Int("\(type)") == UserActivityType.Live.rawValue else { continue }
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
                playerLayer.player?.play()
            }
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
        coverView.snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        self.coverView = coverView
        
        let coverImageView = ImageView(backgroundColor: UIColor.blackColor())
        coverView.add(coverImageView) { $0.edges.equalTo(coverView) }
        
        if UIDevice.currentDevice().supportsBlurring() {
            let blurEffect = UIBlurEffect(style: .Light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            coverView.add(blurView) { $0.edges.equalTo(coverView) }
        } else {
            let blurView = UIView()
            coverView.add(blurView) { $0.edges.equalTo(coverView) }
            blurView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
        }
        
        let wrapNameLabel = Label(preset: .XLarge, weight: .Regular, textColor: UIColor.whiteColor())
        wrapNameLabel.text = wrap?.name
        coverView.add(wrapNameLabel) { (make) -> Void in
            make.centerY.equalTo(coverView).inset(-100)
            make.centerX.equalTo(coverView)
        }
        
        let titleLabel = Label(preset: .Larger, textColor: UIColor.whiteColor())
        titleLabel.text = broadcast.displayTitle()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Center
        coverView.add(titleLabel) { (make) -> Void in
            make.top.equalTo(wrapNameLabel.snp_bottom)
            make.leading.trailing.equalTo(coverView).inset(12)
        }
        
        let messageLabel = Label(preset: .Normal, textColor: UIColor.whiteColor())
        messageLabel.text = text
        coverView.add(messageLabel) { (make) -> Void in
            make.centerY.equalTo(coverView).inset(80)
            make.centerX.equalTo(coverView)
        }
        
        let backButton = Button(icon: "w", size: 36, textColor: UIColor.whiteColor())
        backButton.titleLabel?.font = UIFont.icons(36)
        backButton.setTitleColor(UIColor.whiteColor().darkerColor(), forState: .Highlighted)
        backButton.setTitle("w", forState: .Normal)
        backButton.addTarget(self, touchUpInside: #selector(LiveViewController.close(_:)))
        coverView.add(backButton) { $0.leading.top.equalTo(coverView).inset(12) }
        
        if let user = broadcast.broadcaster {
            if let url = user.avatar?.large where !url.isEmpty {
                coverImageView.url = url
            } else {
                user.fetch({ (_) -> Void in
                    coverImageView.url = user.avatar?.large
                    }, failure: nil)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation { self.playerLayer.frame = self.view.bounds }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if playerItem?.playbackLikelyToKeepUp == true {
            playerLayer.player?.play()
            spinner.stopAnimating()
            removeCoverViewIfNeeded()
        } else {
            spinner.startAnimating()
        }
    }
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
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
