//
//  CallView.swift
//  meWrap
//
//  Created by Yura Granchenko on 06/05/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class CallView: UIView, SINCallDelegate {
    
    let call: SINCall
    let user: User
    let audioController: SINAudioController
    let videoController: SINVideoController
    let avatarView = UserAvatarView(cornerRadius: 100, backgroundColor: Color.orange, placeholderSize: 50)
    let nameLabel = Label(preset: .XLarge, weight: .Regular, textColor: Color.orange)
    let infoLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayLighter)
    let acceptButton = specify(PressButton(icon: "D", size: 24)) {
        $0.clipsToBounds = true
        $0.backgroundColor = Color.green
        $0.cornerRadius = 37
        
    }
    let declineButton = specify(PressButton(icon: "D", size: 24)) {
        $0.clipsToBounds = true
        $0.backgroundColor = Color.dangerRed
        $0.cornerRadius = 37
        $0.transform = CGAffineTransformMakeRotation(2.37)
    }
    let speakerButton = specify(Button.expandableCandyAction("l")) {
        $0.setTitle("m", forState: .Selected)
        $0.setTitleColor(Color.grayLight, forState: .Highlighted)
    }
    let microphoneButton = specify(Button.expandableCandyAction("U")) {
        $0.setTitle("T", forState: .Selected)
        $0.setTitleColor(Color.grayLight, forState: .Highlighted)
    }
    
    private func setupSubviews() {
        nameLabel.textAlignment = .Center
        infoLabel.textAlignment = .Center
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        add(blurView) { $0.edges.equalTo(self) }
        
        let logoView = UIView()
        add(logoView) { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(32)
        }
        let logo1 = logoView.add(Label(icon: "a", size: 44, textColor: Color.orange)) { (make) in
            make.leading.top.bottom.equalTo(logoView)
        }
        let logo2 = logoView.add(Label(icon: "M", size: 74, textColor: Color.orange)) { (make) in
            make.leading.equalTo(logo1.snp_trailing).offset(2)
            make.centerY.equalTo(logo1)
        }
        let callLabel = logoView.add(Label(preset: .Large, weight: .Regular, textColor: .whiteColor())) { (make) in
            make.trailing.equalTo(logoView)
            make.centerY.equalTo(logo1).offset(-2)
            make.leading.equalTo(logo2.snp_trailing).offset(2)
        }
        callLabel.text = "call".ls
        
        add(avatarView) { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(logoView.snp_bottom).offset(50)
            make.size.equalTo(200)
        }
        let circleView = UIView()
        circleView.cornerRadius = 104
        circleView.setBorder(color: Color.orange, width: 2)
        insertSubview(circleView, belowSubview: avatarView)
        circleView.snp_makeConstraints { (make) in
            make.center.equalTo(avatarView)
            make.size.equalTo(208)
        }
        
        self.add(nameLabel, {
            $0.top.equalTo(avatarView.snp_bottom).offset(20)
            $0.centerX.equalTo(self)
            $0.leading.lessThanOrEqualTo(self).offset(12)
            $0.trailing.lessThanOrEqualTo(self).offset(-12)
        })
        
        self.add(infoLabel, {
            $0.top.equalTo(nameLabel.snp_bottom).offset(20)
            $0.centerX.equalTo(self)
            $0.leading.lessThanOrEqualTo(self).offset(12)
            $0.trailing.lessThanOrEqualTo(self).offset(-12)
        })
        
        avatarView.user = user
        nameLabel.text = user.name
        
        if call.direction == .Incoming {
            audioController.startPlayingSoundFile(NSBundle.mainBundle().pathForResource("incoming", ofType: "wav"), loop: true)
            infoLabel.text = "incoming_call".ls
            speakerButton.hidden = true
            microphoneButton.hidden = true
            self.add(acceptButton, {
                $0.bottom.equalTo(self).offset(-20)
                $0.centerX.equalTo(self)
                $0.size.equalTo(74)
            })
            declineButton.cornerRadius = 22
            self.add(declineButton) { make in
                make.centerY.equalTo(acceptButton)
                make.centerX.equalTo(self).multipliedBy(1.5).offset(19)
                make.size.equalTo(44)
            }
            
            startAcceptButtonAnimation()
            startCallAnimation()
            acceptButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.acceptButtonPanning(_:))))
        } else {
            microphoneButton.active = false
            speakerButton.active = false
            infoLabel.text = "waiting_for_response".ls
            self.add(declineButton, {
                $0.bottom.equalTo(self).offset(-20)
                $0.centerX.equalTo(self)
                $0.size.equalTo(74)
            })
        }
        
        add(speakerButton) { (make) in
            make.centerY.equalTo(declineButton)
            make.centerX.equalTo(self).multipliedBy(0.5).offset(-19)
            make.size.equalTo(44)
        }
        
        add(microphoneButton) { (make) in
            make.centerY.equalTo(declineButton)
            make.centerX.equalTo(self).multipliedBy(1.5).offset(19)
            make.size.equalTo(44)
        }
        
        acceptButton.addTarget(self, action: #selector(self.accept(_:)), forControlEvents: .TouchUpInside)
        declineButton.addTarget(self, action: #selector(self.decline(_:)), forControlEvents: .TouchUpInside)
        speakerButton.addTarget(self, action: #selector(self.speaker(_:)), forControlEvents: .TouchUpInside)
        microphoneButton.addTarget(self, action: #selector(self.microphone(_:)), forControlEvents: .TouchUpInside)
    }
    
    private var animationViews: [UIView]?
    
    private func startAcceptButtonAnimation() {
        acceptButton.addAnimation(CABasicAnimation(keyPath: "transform")) {
            $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            $0.toValue = NSValue(CATransform3D: CATransform3DMakeTranslation(0, -32, 0))
            $0.duration = 0.6
            $0.autoreverses = true
            $0.removedOnCompletion = false
            $0.repeatCount = FLT_MAX
        }
    }
    
    private func startCallAnimation() {
        let arrow1 = Label(icon: "z", size: 14, textColor: Color.grayLighter)
        let arrow2 = Label(icon: "z", size: 14, textColor: Color.grayLighter)
        let arrow3 = Label(icon: "z", size: 14, textColor: Color.grayLighter)
        animationViews = [arrow1, arrow2, arrow3]
        insertSubview(arrow1, belowSubview: acceptButton)
        insertSubview(arrow2, belowSubview: acceptButton)
        insertSubview(arrow3, belowSubview: acceptButton)
        
        arrow1.snp_makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.bottom.equalTo(acceptButton.snp_top).offset(-20)
        }
        arrow2.snp_makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.bottom.equalTo(arrow1.snp_top).offset(-2)
        }
        arrow3.snp_makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.bottom.equalTo(arrow2.snp_top).offset(-2)
        }
        arrow1.layer.opacity = 0
        arrow2.layer.opacity = 0
        arrow3.layer.opacity = 0
        arrow1.addAnimation(CAAnimationGroup()) {
            $0.removedOnCompletion = false
            $0.repeatCount = FLT_MAX
            $0.duration = 0.6
            $0.animations = [specify(CABasicAnimation(keyPath: "opacity"), {
                $0.fromValue = 0
                $0.toValue = 1
                $0.duration = 0.1
            }), specify(CABasicAnimation(keyPath: "opacity"), {
                $0.beginTime = 0.1
                $0.fromValue = 1
                $0.toValue = 0
                $0.duration = 0.5
            })]
        }
        
        arrow2.addAnimation(CAAnimationGroup()) {
            $0.removedOnCompletion = false
            $0.repeatCount = FLT_MAX
            $0.duration = 0.6
            $0.animations = [specify(CABasicAnimation(keyPath: "opacity"), {
                $0.beginTime = 0.1
                $0.fromValue = 0
                $0.toValue = 1
                $0.duration = 0.1
            }), specify(CABasicAnimation(keyPath: "opacity"), {
                $0.beginTime = 0.2
                $0.fromValue = 1
                $0.toValue = 0
                $0.duration = 0.4
            })]
        }
        
        arrow3.addAnimation(CAAnimationGroup()) {
            $0.removedOnCompletion = false
            $0.repeatCount = FLT_MAX
            $0.duration = 0.6
            $0.animations = [specify(CABasicAnimation(keyPath: "opacity"), {
                $0.beginTime = 0.2
                $0.fromValue = 0
                $0.toValue = 1
                $0.duration = 0.1
            }), specify(CABasicAnimation(keyPath: "opacity"), {
                $0.beginTime = 0.3
                $0.fromValue = 1
                $0.toValue = 0
                $0.duration = 0.3
            })]
        }
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
    
    func acceptButtonPanning(sender: UIPanGestureRecognizer) {
        if sender.state == .Began {
            acceptButton.transform.ty = (acceptButton.layer.presentationLayer() as? CALayer)?.affineTransform().ty ?? 0
            acceptButton.layer.removeAllAnimations()
            animate(animations: { 
                acceptButton.transform.ty = acceptButton.transform.ty + (sender.locationInView(self).y - acceptButton.center.y)
            })
        } else if sender.state == .Changed {
            acceptButton.transform.ty = 0
            acceptButton.transform.ty = sender.locationInView(self).y - acceptButton.center.y
        } else {
            if acceptButton.transform.ty <= -acceptButton.height {
                accept(acceptButton)
            } else {
                animate(animations: {
                    acceptButton.transform.ty = 0
                })
                startAcceptButtonAnimation()
            }
        }
    }
    
    lazy var spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
    
    func accept(sender: UIButton) {
        acceptButton.hidden = true
        spinner.color = Color.orange
        add(spinner) { (make) in
            make.center.equalTo(acceptButton)
        }
        spinner.startAnimating()
        declineButton.userInteractionEnabled = false
        sender.layer.removeAllAnimations()
        audioController.stopPlayingSoundFile()
        call.answer()
        sender.userInteractionEnabled = false
        animationViews?.all({ $0.removeFromSuperview() })
    }
    
    func decline(sender: UIButton) {
        audioController.stopPlayingSoundFile()
        call.hangup()
        removeFromSuperview()
    }
    
    func speaker(sender: UIButton) {
        sender.selected = !sender.selected
        if sender.selected {
            audioController.enableSpeaker()
        } else {
            audioController.disableSpeaker()
        }
    }
    
    func microphone(sender: UIButton) {
        sender.selected = !sender.selected
        if sender.selected {
            audioController.unmute()
        } else {
            audioController.mute()
        }
    }
    
    func present() {
        let view = UIWindow.mainWindow
        view.add(self) { $0.edges.equalTo(view) }
        setupSubviews()
        alpha = 0.0
        UIView.animateWithDuration(0.5) {
            self.alpha = 1.0
        }
    }
    
    func callDidProgress(call: SINCall!) {
        audioController.startPlayingSoundFile(NSBundle.mainBundle().pathForResource("ringback", ofType: "wav"), loop: true)
    }
    
    func callDidEstablish(call: SINCall!) {
        declineButton.userInteractionEnabled = true
        audioController.stopPlayingSoundFile()
        speakerButton.hidden = false
        microphoneButton.hidden = false
        acceptButton.loading = false
        spinner.removeFromSuperview()
        acceptButton.removeFromSuperview()
        declineButton.cornerRadius = 37
        declineButton.snp_remakeConstraints { make in
            make.bottom.equalTo(self).offset(-20)
            make.centerX.equalTo(self)
            make.size.equalTo(74)
        }
        microphoneButton.active = true
        speakerButton.active = true
        microphoneButton.selected = true
        infoLabel.textColor = .whiteColor()
        updateTimer()
    }
    
    private var time = 0
    
    private func updateTimer() {
        infoLabel.text = String(format:"%02i:%02i", time / 60, time % 60)
        Dispatch.mainQueue.after(1) { [weak self] () in
            if let view = self {
                view.time = view.time + 1
                view.updateTimer()
            }
        }
    }
    
    func callDidEnd(call: SINCall!) {
        audioController.stopPlayingSoundFile()
        videoController.remoteView().removeFromSuperview()
        self.removeFromSuperview()
    }
    
    func callDidAddVideoTrack(call: SINCall!) {}
}