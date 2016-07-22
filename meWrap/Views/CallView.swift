//
//  CallView.swift
//  meWrap
//
//  Created by Yura Granchenko on 06/05/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class CallView: UIView {
    
    let call: SINCall
    let user: User
    let audioController: SINAudioController
    let videoController: SINVideoController
    let titleLabel = Label(preset: .XLarge, weight: .Regular, textColor: UIColor.whiteColor())
    let infoLabel = Label(preset: .Normal, weight: .Regular, textColor: UIColor.whiteColor())
    let acceptIconButton = specify(Button(icon: "D", size: 24)) {
        $0.clipsToBounds = true
        $0.backgroundColor = Color.green
        $0.cornerRadius = 28.0
        
    }
    let declineIconButton = specify(Button(icon: "D", size: 24)) {
        $0.clipsToBounds = true
        $0.backgroundColor = Color.dangerRed
        $0.cornerRadius = 28.0
        $0.transform = CGAffineTransformMakeRotation(2.37)
    }
    
    let localView = UIView()
    let remoteView = UIView()
    
    func setupTopWindow() {
        let view = UIWindow.mainWindow
        frame = view.frame
        view.addSubview(self)
        snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        setupSubviews()
        alpha = 0.0
        UIView.animateWithDuration(0.5) {
            self.alpha = 1.0
        }
    }
    
    private func setupSubviews() {
        titleLabel.textAlignment = .Center
        infoLabel.textAlignment = .Center
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        add(blurView) { $0.edges.equalTo(self) }
        
        self.add(localView, {
            $0.trailing.equalTo(self).inset(20)
            $0.top.equalTo(self).inset(40)
            $0.size.equalTo(100)
        })
        self.add(remoteView, {
            $0.leading.trailing.bottom.equalTo(self).inset(20)
            $0.top.equalTo(localView.snp_bottom).offset(20)
        })
        
        self.add(declineIconButton, {
            $0.bottom.equalTo(self).offset(-70)
            $0.centerX.equalTo(self).multipliedBy(0.5)
            $0.size.equalTo(56.0)
        })
        self.add(acceptIconButton, {
            $0.bottom.equalTo(self).offset(-70)
            $0.centerX.equalTo(self).multipliedBy(1.5)
            $0.size.equalTo(56.0)
        })
        self.add(titleLabel, {
            $0.leading.equalTo(self).inset(20)
            $0.top.equalTo(self).inset(40)
            $0.trailing.lessThanOrEqualTo(localView.snp_leading).inset(100)
        })
        self.add(infoLabel, {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp_bottom)
            $0.trailing.lessThanOrEqualTo(localView.snp_leading).inset(20)
        })
        
        acceptIconButton.addTarget(self, action: #selector(self.accept(_:)), forControlEvents: .TouchUpInside)
        declineIconButton.addTarget(self, action: #selector(self.decline(_:)), forControlEvents: .TouchUpInside)
        localView.addGestureRecognizer(UISwipeGestureRecognizer(target: self, action: #selector(self.switchCamera(_:))))
        remoteView.hidden = true
        localView.backgroundColor = UIColor.blackColor()
        remoteView.backgroundColor = UIColor.blackColor()
    }
    
    func showDeclineButton() {
        declineIconButton.snp_updateConstraints {
            $0.centerX.equalTo(self)
        }
        acceptIconButton.hidden = true
    }
    
    func updateViews() {
        declineIconButton.snp_updateConstraints {
            $0.centerX.equalTo(self).multipliedBy(0.5)
        }
        acceptIconButton.snp_updateConstraints {
            $0.centerX.equalTo(self).multipliedBy(1.5)
        }
        acceptIconButton.hidden = false
        declineIconButton.hidden = false
    }
    
    func presentFullScreen(sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        if view.sin_isFullscreen() {
            view.sin_disableFullscreen(true)
        } else {
            view.sin_enableFullscreen(true)
        }
    }
    
    func switchCamera(sender: UISwipeGestureRecognizer) {
        videoController.captureDevicePosition = SINToggleCaptureDevicePosition(videoController.captureDevicePosition)
    }
    
    required init(user: User, call: SINCall, audioController: SINAudioController, videoController: SINVideoController) {
        self.call = call
        self.user = user
        self.audioController = audioController
        self.videoController = videoController
        super.init(frame: CGRect.zero)
        call.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func accept(sender: AnyObject) {
        remoteView.hidden = false
        audioController.stopPlayingSoundFile()
        call.answer()
        showDeclineButton()
    }
    
    func decline(sender: AnyObject) {
        audioController.stopPlayingSoundFile()
        call.hangup()
        updateViews()
        removeFromSuperview()
    }
    
    func present() {
        setupTopWindow()
        if call.direction == .Incoming {
            audioController.startPlayingSoundFile(NSBundle.mainBundle().pathForResource("incoming", ofType: "wav"), loop: true)
            audioController.enableSpeaker()
            titleLabel.text = user.name
            infoLabel.text = "calling..."
            updateViews()
        } else {
            titleLabel.text = user.name
            infoLabel.text = "calling..."
            showDeclineButton()
        }
        layoutIfNeeded()
        if let localView = videoController.localView() where call.details.videoOffered == true {
            self.localView.addSubview(localView)
            localView.contentMode = .ScaleAspectFill
            localView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.presentFullScreen(_:))))
        }
    }
}

extension CallView: SINCallDelegate {
    
    func callDidProgress(call: SINCall!) {
        infoLabel.text = "ringing..."
        audioController.startPlayingSoundFile(NSBundle.mainBundle().pathForResource("ringback", ofType: "wav"), loop: true)
    }
    
    func callDidEstablish(call: SINCall!) {
        audioController.stopPlayingSoundFile()
        showDeclineButton()
        infoLabel.text = "calling..."
        remoteView.hidden = false
    }
    
    func callDidEnd(call: SINCall!) {
        audioController.stopPlayingSoundFile()
        audioController.disableSpeaker()
        videoController.remoteView().removeFromSuperview()
        self.removeFromSuperview()
    }
    
    func callDidAddVideoTrack(call: SINCall!) {
        guard let remoteView = videoController.remoteView() else { return }
        self.remoteView.addSubview(remoteView)
        remoteView.contentMode = .ScaleAspectFill
        remoteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.presentFullScreen(_:))))
    }
}