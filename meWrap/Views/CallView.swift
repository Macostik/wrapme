//
//  CallView.swift
//  meWrap
//
//  Created by Yura Granchenko on 06/05/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

//
//  CallView.swift
//  meWrap
//
//  Created by Yura Granchenko on 06/05/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit
import CoreTelephony

class CallViewController: UIViewController, SINCallDelegate {
    
    private let isVideo: Bool
    private let call: SINCall
    private let user: User
    private let audioController: SINAudioController
    private let videoController: SINVideoController
    private weak var topView: UIView?
    private let nameLabel = Label(preset: .XLarge, weight: .Regular, textColor: Color.orange)
    private let infoLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayLighter)
    private lazy var acceptButton: PressButton = specify(PressButton(icon: self.isVideo ? "+" : "D", size: 24)) {
        $0.clipsToBounds = true
        $0.backgroundColor = Color.green
        $0.cornerRadius = 37
    }
    private let declineButton = specify(PressButton(icon: "D", size: 24)) {
        $0.clipsToBounds = true
        $0.backgroundColor = Color.dangerRed
        $0.cornerRadius = 37
        $0.transform = CGAffineTransformMakeRotation(2.37)
        $0.disabledColor = Color.grayLighter
    }
    private weak var speakerButton: Button?
    private weak var microphoneButton: Button?
    
    required init(user: User, call: SINCall, isVideo: Bool, audioController: SINAudioController, videoController: SINVideoController) {
        self.call = call
        self.user = user
        self.isVideo = isVideo
        self.audioController = audioController
        self.videoController = videoController
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .OverCurrentContext
        call.delegate = self
        Network.network.subscribe(self) { [unowned self] (value) in
            if !value {
                self.endCall(nil)
                self.infoLabel.text = "call_connection_broken".ls
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    private weak var remoteVideoView: UIView?
    
    private weak var localVideoView: UIView?
    
    private var audioPlayer: AVAudioPlayer? {
        didSet {
            oldValue?.stop()
        }
    }
    
    func startPlayingSound(name: String, loop: Bool) {
        guard let path = NSBundle.mainBundle().pathForResource(name, ofType: "wav") else {
            stopPlayingSound()
            return
        }
        let audioPlayer = try? AVAudioPlayer(contentsOfURL: NSURL.fileURLWithPath(path))
        audioPlayer?.numberOfLoops = loop ? -1 : 0
        self.audioPlayer = audioPlayer
        audioPlayer?.play()
    }
    
    func stopPlayingSound() {
        audioPlayer = nil
    }
    
    private func createTopView() {
        self.topView?.removeFromSuperview()
        let topView = UIView()
        let logoView = UIView()
        let circleView = UIView()
        let avatarView = UserAvatarView(cornerRadius: 100, backgroundColor: Color.orange, placeholderSize: 50)
        topView.add(logoView) { (make) in
            make.centerX.equalTo(topView)
            make.top.equalTo(topView).offset(32)
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
        
        topView.add(avatarView) { (make) in
            make.centerX.equalTo(topView)
            make.top.equalTo(logoView.snp_bottom).offset(50)
            make.size.equalTo(200)
            make.bottom.equalTo(topView)
        }
        
        circleView.cornerRadius = 104
        circleView.setBorder(color: Color.orange, width: 2)
        topView.insertSubview(circleView, belowSubview: avatarView)
        circleView.snp_makeConstraints { (make) in
            make.center.equalTo(avatarView)
            make.size.equalTo(208)
        }
        avatarView.user = user
        view.add(topView) { (make) in
            make.leading.top.trailing.equalTo(view)
        }
        self.topView = topView
    }
    
    override func loadView() {
        super.loadView()
        
        audioController.unmute()
        
        view.backgroundColor = UIColor.blackColor()
        
        createTopView()
        
        nameLabel.textAlignment = .Center
        infoLabel.textAlignment = .Center
        
        layoutNameAndInfoLabels()
        
        nameLabel.text = user.name
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: [])
        _ = try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        if call.direction == .Incoming {
            _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.Speaker)
            startPlayingSound("incoming", loop: true)
            infoLabel.text = "incoming_call".ls
            view.add(acceptButton, {
                $0.bottom.equalTo(view).offset(-20)
                $0.centerX.equalTo(view)
                $0.size.equalTo(74)
            })
            declineButton.cornerRadius = 22
            view.add(declineButton) { make in
                make.centerY.equalTo(acceptButton)
                make.centerX.equalTo(view).multipliedBy(1.5).offset(19)
                make.size.equalTo(44)
            }
            
            startAcceptButtonAnimation()
            startCallAnimation()
            acceptButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.acceptButtonPanning(_:))))
            acceptButton.addTarget(self, action: #selector(self.accept(_:)), forControlEvents: .TouchUpInside)
            
        } else {
            _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(isVideo ? .Speaker : .None)
            infoLabel.text = "waiting_for_response".ls
            view.add(declineButton, {
                $0.bottom.equalTo(view).offset(-20)
                $0.centerX.equalTo(view)
                $0.size.equalTo(74)
            })
        }
        
        if isVideo {
            if let localVideoView = videoController.localView() {
                videoController.captureDevicePosition = .Front
                let localVideoContainer = UIView()
                localVideoContainer.backgroundColor = UIColor.blackColor()
                view.add(localVideoContainer, { (make) in
                    make.top.equalTo(view).offset(25)
                    make.leading.equalTo(view).offset(5)
                    make.width.equalTo(view).multipliedBy(0.25)
                    make.height.equalTo(localVideoContainer.snp_width).dividedBy(0.75)
                })
                localVideoContainer.layoutIfNeeded()
                localVideoContainer.addSubview(localVideoView)
                localVideoView.contentMode = .ScaleAspectFill
                let toggleCameraButton = PressButton(icon: "}", size: 20)
                toggleCameraButton.addTarget(self, touchUpInside: #selector(self.toggleCamera(_:)))
                localVideoContainer.add(toggleCameraButton, { (make) in
                    make.centerX.equalTo(localVideoContainer)
                    make.bottom.equalTo(localVideoContainer).offset(-5)
                })
                self.localVideoView = localVideoContainer
            }
        }
        
        declineButton.addTarget(self, action: #selector(self.decline(_:)), forControlEvents: .TouchUpInside)
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

        func addAnimationArrow(beginTime beginTime: CFTimeInterval) -> Label {
            let arrow = Label(icon: "z", size: 14, textColor: Color.grayLighter)
            view.insertSubview(arrow, belowSubview: acceptButton)
            arrow.layer.opacity = 0
            arrow.addAnimation(CAAnimationGroup()) {
                $0.removedOnCompletion = false
                $0.repeatCount = FLT_MAX
                $0.duration = 0.6
                $0.animations = [specify(CABasicAnimation(keyPath: "opacity"), {
                    $0.beginTime = beginTime
                    $0.fromValue = 0
                    $0.toValue = 1
                    $0.duration = 0.1
                }), specify(CABasicAnimation(keyPath: "opacity"), {
                    $0.beginTime = beginTime + 0.1
                    $0.fromValue = 1
                    $0.toValue = 0
                    $0.duration = 0.6 - $0.beginTime
                })]
            }
            return arrow
        }
        
        let arrow1 = addAnimationArrow(beginTime: 0)
        let arrow2 = addAnimationArrow(beginTime: 0.1)
        let arrow3 = addAnimationArrow(beginTime: 0.2)
        
        animationViews = [arrow1, arrow2, arrow3]
        
        arrow1.snp_makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.bottom.equalTo(acceptButton.snp_top).offset(-20)
        }
        arrow2.snp_makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.bottom.equalTo(arrow1.snp_top).offset(-2)
        }
        arrow3.snp_makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.bottom.equalTo(arrow2.snp_top).offset(-2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func acceptButtonPanning(sender: UIPanGestureRecognizer) {
        if sender.state == .Began {
            acceptButton.transform.ty = (acceptButton.layer.presentationLayer() as? CALayer)?.affineTransform().ty ?? 0
            acceptButton.layer.removeAllAnimations()
            animate(animations: {
                acceptButton.transform.ty = acceptButton.transform.ty + (sender.locationInView(view).y - acceptButton.center.y)
            })
        } else if sender.state == .Changed {
            acceptButton.transform.ty = 0
            acceptButton.transform.ty = sender.locationInView(view).y - acceptButton.center.y
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
    
    private lazy var spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
    
    func accept(sender: UIButton) {
        user.p2pWrap?.updateCallDate(nil)
        acceptButton.hidden = true
        spinner.color = Color.orange
        view.add(spinner) { (make) in
            make.center.equalTo(acceptButton)
        }
        spinner.startAnimating()
        sender.layer.removeAllAnimations()
        if call.direction == .Incoming && !isVideo {
            _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.None)
        }
        stopPlayingSound()
        call.answer()
        sender.userInteractionEnabled = false
        animationViews?.all({ $0.removeFromSuperview() })
    }
    
    func decline(sender: UIButton) {
        sender.enabled = false
        user.p2pWrap?.updateCallDate(nil)
        call.hangup()
    }
    
    func speaker(sender: UIButton) {
        sender.selected = !sender.selected
        _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(sender.selected ? .Speaker : .None)
    }
    
    func microphone(sender: UIButton) {
        sender.selected = !sender.selected
        if sender.selected {
            audioController.unmute()
        } else {
            audioController.mute()
        }
    }
    
    func redial(sender: UIButton) {
        close()
        CallCenter.center.call(user, isVideo: isVideo)
    }
    
    func close(sender: UIButton) {
        UIView.animateWithDuration(0.5, animations: {
            self.view.alpha = 0
            }, completion: { (_) in
                self.close()
        })
    }
    
    func toggleCamera(sender: UIButton) {
        videoController.captureDevicePosition = SINToggleCaptureDevicePosition(videoController.captureDevicePosition)
    }
    
    static var isVisible: Bool {
        return UINavigationController.main.topViewController is CallViewController
    }
    
    func present() {
        UIWindow.mainWindow.endEditing(true)
        UINavigationController.main.presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
        UINavigationController.main.push(self)
    }
    
    func callDidProgress(call: SINCall!) {
        startPlayingSound("ringback", loop: true)
    }
    
    private weak var topVideoView: UIView?
    private weak var bottomVideoView: UIView?
    
    func callDidEstablish(call: SINCall!) {
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: isVideo ? .DefaultToSpeaker : [])
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        if isVideo {
            _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.Speaker)
        } else {
            let speakerButton = specify(Button.expandableCandyAction("l")) {
                $0.setTitle("m", forState: .Selected)
                $0.setTitleColor(Color.grayLight, forState: .Highlighted)
                $0.addTarget(self, action: #selector(self.speaker(_:)), forControlEvents: .TouchUpInside)
            }
            self.speakerButton = view.add(speakerButton) { (make) in
                make.centerY.equalTo(declineButton)
                make.centerX.equalTo(view).multipliedBy(0.5).offset(-19)
                make.size.equalTo(44)
            }
        }
        
        let microphoneButton = specify(Button.expandableCandyAction("U")) {
            $0.setTitle("T", forState: .Selected)
            $0.setTitleColor(Color.grayLight, forState: .Highlighted)
            $0.addTarget(self, action: #selector(self.microphone(_:)), forControlEvents: .TouchUpInside)
            $0.selected = true
        }
        self.microphoneButton = view.add(microphoneButton) { (make) in
            make.centerY.equalTo(declineButton)
            make.centerX.equalTo(view).multipliedBy(1.5).offset(19)
            make.size.equalTo(44)
        }
        
        stopPlayingSound()
        if call.direction == .Incoming {
            acceptButton.loading = false
            acceptButton.removeFromSuperview()
            spinner.removeFromSuperview()
        }
        
        declineButton.cornerRadius = 37
        infoLabel.textColor = .whiteColor()
        updateTimerBlock = { [weak self] _ in
            if let view = self where view.call.state != .Ended {
                if CallCenter.nativeCenter.currentCalls?.count ?? 0 == 0 {
                    view.time = view.time + 1
                }
                view.updateTimer()
            }
        }
        updateTimer()
        
        if self.isVideo {
            
            topView?.removeFromSuperview()

            let topVideoView = UIView()
            
            self.topVideoView = topVideoView

            topVideoView.backgroundColor = UIColor(white: 0, alpha: 0.75)
            
            view.add(topVideoView, { (make) in
                make.leading.top.trailing.equalTo(view)
            })

            nameLabel.removeFromSuperview()
            topVideoView.add(nameLabel, {
                $0.top.equalTo(topVideoView).offset(25)
                $0.centerX.equalTo(topVideoView)
                $0.leading.lessThanOrEqualTo(topVideoView).offset(12)
                $0.trailing.lessThanOrEqualTo(topVideoView).offset(-12)
            })
            infoLabel.removeFromSuperview()
            topVideoView.add(infoLabel, {
                $0.top.equalTo(nameLabel.snp_bottom).offset(2)
                $0.centerX.equalTo(topVideoView)
                $0.leading.lessThanOrEqualTo(topVideoView).offset(12)
                $0.trailing.lessThanOrEqualTo(topVideoView).offset(-12)
                $0.bottom.equalTo(topVideoView).offset(-5)
            })
            
            let bottomVideoView = UIView()
            self.bottomVideoView = bottomVideoView
            bottomVideoView.backgroundColor = UIColor(white: 0, alpha: 0.75)
            
            view.add(bottomVideoView, { (make) in
                make.leading.bottom.trailing.equalTo(view)
            })
            
            bottomVideoView.addSubview(declineButton)
            declineButton.snp_remakeConstraints(closure: { (make) in
                make.top.equalTo(bottomVideoView).offset(5)
                make.bottom.equalTo(bottomVideoView).offset(-5)
                make.centerX.equalTo(bottomVideoView)
                make.size.equalTo(74)
            })
            
            bottomVideoView.addSubview(microphoneButton)
            microphoneButton.snp_remakeConstraints { (make) in
                make.centerY.equalTo(declineButton)
                make.centerX.equalTo(bottomVideoView).multipliedBy(1.5).offset(19)
                make.size.equalTo(44)
            }
            
            if let localVideoView = localVideoView {
                view.addSubview(localVideoView)
                localVideoView.snp_remakeConstraints { (make) in
                    make.leading.equalTo(view).offset(5)
                    make.top.equalTo(topVideoView.snp_bottom).offset(5)
                    make.width.equalTo(topVideoView).multipliedBy(0.25)
                    make.height.equalTo(localVideoView.snp_width).dividedBy(0.75)
                }
            }
            
            Dispatch.mainQueue.after(3, block: { [weak self] () in
                self?.setVideoViewsHidden(true)
                })
            
        } else {
            declineButton.snp_remakeConstraints { make in
                make.bottom.equalTo(view).offset(-20)
                make.centerX.equalTo(view)
                make.size.equalTo(74)
            }
        }
    }
    
    private func setVideoViewsHidden(hidden: Bool) {
        guard let topVideoView = topVideoView else { return }
        guard let bottomVideoView = bottomVideoView else { return }
        animate(animations: {
            topVideoView.alpha = hidden ? 0 : 1
            topVideoView.snp_remakeConstraints(closure: { (make) in
                if hidden {
                    make.leading.trailing.equalTo(view)
                    make.bottom.equalTo(view.snp_top).offset(20)
                } else {
                    make.leading.top.trailing.equalTo(view)
                }
            })
            bottomVideoView.snp_remakeConstraints(closure: { (make) in
                if hidden {
                    make.leading.trailing.equalTo(view)
                    make.top.equalTo(view.snp_bottom)
                } else {
                    make.leading.bottom.trailing.equalTo(view)
                }
            })
            view.layoutIfNeeded()
        })
    }
    
    private var time = 0
    
    private var updateTimerBlock: (() -> ())?
    
    private func updateTimer() {
        infoLabel.text = String(format:"%02i:%02i", time / 60, time % 60)
        Dispatch.mainQueue.after(1) { [weak self] () in
            self?.updateTimerBlock?()
        }
    }
    
    private func close() {
        navigationController?.popViewControllerAnimated(false)
        user.p2pWrap?.notifyOnUpdate(.Default)
        _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.Speaker)
    }
    
    private func callEndReason(call: SINCall) -> String? {
        if call.direction == .Incoming {
            return nil
        } else {
            switch call.details.endCause {
            case .None, .Timeout, .NoAnswer, .Error:
                return "no_answer".ls
            case .Denied:
                return "friend_is_busy".ls
            case .HungUp, .Canceled, .OtherDeviceAnswered:
                return nil
            }
        }
    }
    
    func callDidEnd(call: SINCall!) {
        endCall(callEndReason(call))
    }
    
    private func layoutNameAndInfoLabels() {
        guard let topView = topView else { return }
        view.addSubview(nameLabel)
        nameLabel.snp_remakeConstraints {
            $0.top.equalTo(topView.snp_bottom).offset(20)
            $0.centerX.equalTo(view)
            $0.leading.lessThanOrEqualTo(view).offset(12)
            $0.trailing.lessThanOrEqualTo(view).offset(-12)
        }
        view.addSubview(infoLabel)
        infoLabel.snp_remakeConstraints {
            $0.top.equalTo(nameLabel.snp_bottom).offset(20)
            $0.centerX.equalTo(view)
            $0.leading.lessThanOrEqualTo(view).offset(12)
            $0.trailing.lessThanOrEqualTo(view).offset(-12)
        }
    }
    
    private func endCall(reason: String?) {
        if isVideo {
            videoController.captureDevicePosition = .Front
            if topVideoView != nil {
                topVideoView?.removeFromSuperview()
                bottomVideoView?.removeFromSuperview()
                remoteVideoView?.removeFromSuperview()
                createTopView()
                layoutNameAndInfoLabels()
            }
            localVideoView?.removeFromSuperview()
        }
        updateTimerBlock = nil
        stopPlayingSound()
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient, withOptions: [])
        _ = try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        startPlayingSound("hangup", loop: false)
        microphoneButton?.removeFromSuperview()
        speakerButton?.removeFromSuperview()
        infoLabel.textColor = Color.grayLighter
        declineButton.hidden = true
        if let reason = reason {
            infoLabel.text = reason
            let redialButton = specify(PressButton(icon: "D", size: 24)) {
                $0.clipsToBounds = true
                $0.backgroundColor = Color.green
                $0.cornerRadius = 37
                
            }
            let closeButton = specify(PressButton(icon: "D", size: 24)) {
                $0.clipsToBounds = true
                $0.backgroundColor = Color.dangerRed
                $0.cornerRadius = 37
                $0.transform = CGAffineTransformMakeRotation(2.37)
            }
            redialButton.addTarget(self, action: #selector(self.redial(_:)), forControlEvents: .TouchUpInside)
            closeButton.addTarget(self, action: #selector(self.close(_:)), forControlEvents: .TouchUpInside)
            view.add(redialButton, {
                $0.bottom.equalTo(view).offset(-20)
                $0.centerX.equalTo(view).multipliedBy(1.5)
                $0.size.equalTo(74)
            })
            view.add(closeButton, {
                $0.bottom.equalTo(view).offset(-20)
                $0.centerX.equalTo(view).multipliedBy(0.5)
                $0.size.equalTo(74)
            })
        } else {
            animationViews?.all({ $0.removeFromSuperview() })
            infoLabel.text = "call_ended".ls
            view.userInteractionEnabled = false
            if call.direction == .Incoming {
                acceptButton.hidden = true
            }
            UIView.animateWithDuration(0.5, delay: 1.5, options:[], animations: {
                self.view.alpha = 0
                }, completion: { (_) in
                    self.close()
            })
        }
    }
    
    func callDidAddVideoTrack(call: SINCall!) {
        if let remoteVideoView = videoController.remoteView() {
            view.layoutIfNeeded()
            view.addSubview(remoteVideoView)
            self.remoteVideoView = remoteVideoView
            remoteVideoView.contentMode = .ScaleAspectFill
            view.sendSubviewToBack(remoteVideoView)
            remoteVideoView.tapped({ [weak self] (_) in
                self?.setVideoViewsHidden(self?.topVideoView?.frame.origin.y == 0)
                })
        }
    }
}