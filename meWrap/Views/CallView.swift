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

//import UIKit
//import SnapKit
//
//class CallView: UIView {
//    
//    let call: SINCall
//    let user: User
//    let audioController: SINAudioController
//    let videoController: SINVideoController
//    let titleLabel = Label(preset: .XLarge, weight: .Regular, textColor: UIColor.whiteColor())
//    let infoLabel = Label(preset: .Normal, weight: .Regular, textColor: UIColor.whiteColor())
//    let acceptIconButton = specify(Button(icon: "D", size: 24)) {
//        $0.clipsToBounds = true
//        $0.backgroundColor = Color.green
//        $0.cornerRadius = 28.0
//        
//    }
//    let declineIconButton = specify(Button(icon: "D", size: 24)) {
//        $0.clipsToBounds = true
//        $0.backgroundColor = Color.dangerRed
//        $0.cornerRadius = 28.0
//        $0.transform = CGAffineTransformMakeRotation(2.37)
//    }
//    
//    static var isVisible: Bool {
//        return true
//    }
//    
//    let localView = UIView()
//    let remoteView = UIView()
//    
//    func setupTopWindow() {
//        let view = UIWindow.mainWindow
//        frame = view.frame
//        view.addSubview(self)
//        snp_makeConstraints(closure: { $0.edges.equalTo(view) })
//        setupSubviews()
//        alpha = 0.0
//        UIView.animateWithDuration(0.5) {
//            self.alpha = 1.0
//        }
//    }
//    
//    private func setupSubviews() {
//        titleLabel.textAlignment = .Center
//        infoLabel.textAlignment = .Center
//        
//        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
//        add(blurView) { $0.edges.equalTo(self) }
//        
//        self.add(remoteView, {
//            $0.edges.equalTo(self)
//        })
//        
//        self.add(localView, {
//            $0.trailing.equalTo(self).inset(20)
//            $0.top.equalTo(self).inset(40)
//            $0.size.equalTo(100)
//        })
//        
//        self.add(declineIconButton, {
//            $0.bottom.equalTo(self).offset(-70)
//            $0.centerX.equalTo(self).multipliedBy(0.5)
//            $0.size.equalTo(56.0)
//        })
//        self.add(acceptIconButton, {
//            $0.bottom.equalTo(self).offset(-70)
//            $0.centerX.equalTo(self).multipliedBy(1.5)
//            $0.size.equalTo(56.0)
//        })
//        self.add(titleLabel, {
//            $0.leading.equalTo(self).inset(20)
//            $0.top.equalTo(self).inset(40)
//            $0.trailing.lessThanOrEqualTo(localView.snp_leading).inset(100)
//        })
//        self.add(infoLabel, {
//            $0.leading.equalTo(titleLabel)
//            $0.top.equalTo(titleLabel.snp_bottom)
//            $0.trailing.lessThanOrEqualTo(localView.snp_leading).inset(20)
//        })
//        
//        acceptIconButton.addTarget(self, action: #selector(self.accept(_:)), forControlEvents: .TouchUpInside)
//        declineIconButton.addTarget(self, action: #selector(self.decline(_:)), forControlEvents: .TouchUpInside)
//        localView.addGestureRecognizer(UISwipeGestureRecognizer(target: self, action: #selector(self.switchCamera(_:))))
//        remoteView.hidden = true
//        localView.backgroundColor = UIColor.blackColor()
//        remoteView.backgroundColor = UIColor.blackColor()
//    }
//    
//    func showDeclineButton() {
//        declineIconButton.snp_updateConstraints {
//            $0.centerX.equalTo(self)
//        }
//        acceptIconButton.hidden = true
//    }
//    
//    func updateViews() {
//        declineIconButton.snp_updateConstraints {
//            $0.centerX.equalTo(self).multipliedBy(0.5)
//        }
//        acceptIconButton.snp_updateConstraints {
//            $0.centerX.equalTo(self).multipliedBy(1.5)
//        }
//        acceptIconButton.hidden = false
//        declineIconButton.hidden = false
//    }
//    
//    func presentFullScreen(sender: UITapGestureRecognizer) {
//        guard let view = sender.view else { return }
//        if view.sin_isFullscreen() {
//            view.sin_disableFullscreen(true)
//        } else {
//            view.sin_enableFullscreen(true)
//        }
//    }
//    
//    func switchCamera(sender: UISwipeGestureRecognizer) {
//        videoController.captureDevicePosition = SINToggleCaptureDevicePosition(videoController.captureDevicePosition)
//    }
//    
//    required init(user: User, call: SINCall, isVideo: Bool, audioController: SINAudioController, videoController: SINVideoController) {
//        self.call = call
//        self.user = user
//        self.audioController = audioController
//        self.videoController = videoController
//        super.init(frame: CGRect.zero)
//        call.delegate = self
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func accept(sender: AnyObject) {
//        remoteView.hidden = false
//        audioController.stopPlayingSoundFile()
//        call.answer()
//        showDeclineButton()
//    }
//    
//    func decline(sender: AnyObject) {
//        audioController.stopPlayingSoundFile()
//        call.hangup()
//        updateViews()
//        removeFromSuperview()
//    }
//    
//    func present() {
//        setupTopWindow()
//        if call.direction == .Incoming {
//            audioController.startPlayingSoundFile(NSBundle.mainBundle().pathForResource("incoming", ofType: "wav"), loop: true)
//            audioController.enableSpeaker()
//            titleLabel.text = user.name
//            infoLabel.text = "calling..."
//            updateViews()
//        } else {
//            titleLabel.text = user.name
//            infoLabel.text = "calling..."
//            showDeclineButton()
//        }
//        layoutIfNeeded()
//        if let localView = videoController.localView() where call.details.videoOffered == true {
//            self.localView.addSubview(localView)
//            localView.contentMode = .ScaleAspectFill
//            localView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.presentFullScreen(_:))))
//        }
//    }
//}
//
//extension CallView: SINCallDelegate {
//    
//    func callDidProgress(call: SINCall!) {
//        infoLabel.text = "ringing..."
//        audioController.startPlayingSoundFile(NSBundle.mainBundle().pathForResource("ringback", ofType: "wav"), loop: true)
//    }
//    
//    func callDidEstablish(call: SINCall!) {
//        audioController.stopPlayingSoundFile()
//        showDeclineButton()
//        infoLabel.text = "calling..."
//        remoteView.hidden = false
//    }
//    
//    func callDidEnd(call: SINCall!) {
//        audioController.stopPlayingSoundFile()
//        audioController.disableSpeaker()
//        videoController.remoteView().removeFromSuperview()
//        self.removeFromSuperview()
//    }
//    
//    func callDidAddVideoTrack(call: SINCall!) {
//        guard let remoteView = videoController.remoteView() else { return }
//        self.remoteView.addSubview(remoteView)
//        remoteView.contentMode = .ScaleAspectFill
//        remoteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.presentFullScreen(_:))))
//    }
//}





import UIKit
import SnapKit
import CoreTelephony

class CallView: UIView, SINCallDelegate {
    
    private let isVideo: Bool
    private let call: SINCall
    private let user: User
    private let audioController: SINAudioController
    private let videoController: SINVideoController
    private let avatarView = UserAvatarView(cornerRadius: 100, backgroundColor: Color.orange, placeholderSize: 50)
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
    private let speakerButton = specify(Button.expandableCandyAction("l")) {
        $0.setTitle("m", forState: .Selected)
        $0.setTitleColor(Color.grayLight, forState: .Highlighted)
    }
    private let microphoneButton = specify(Button.expandableCandyAction("U")) {
        $0.setTitle("T", forState: .Selected)
        $0.setTitleColor(Color.grayLight, forState: .Highlighted)
    }
    
    private let redialButton = specify(PressButton(icon: "D", size: 24)) {
        $0.clipsToBounds = true
        $0.backgroundColor = Color.green
        $0.cornerRadius = 37
        
    }
    private let closeButton = specify(PressButton(icon: "D", size: 24)) {
        $0.clipsToBounds = true
        $0.backgroundColor = Color.dangerRed
        $0.cornerRadius = 37
        $0.transform = CGAffineTransformMakeRotation(2.37)
    }
    
    let logoView = UIView()
    
    let circleView = UIView()
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    required init(user: User, call: SINCall, isVideo: Bool, audioController: SINAudioController, videoController: SINVideoController) {
        self.call = call
        self.user = user
        self.isVideo = isVideo
        self.audioController = audioController
        self.videoController = videoController
        super.init(frame: UIScreen.mainScreen().bounds)
        call.delegate = self
        Network.network.subscribe(self) { [unowned self] (value) in
            if !value {
                self.endCall(nil)
                self.infoLabel.text = "call_connection_broken".ls
            }
        }
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
    
    private func setupSubviews() {
        nameLabel.textAlignment = .Center
        infoLabel.textAlignment = .Center
        
        add(blurView) { $0.edges.equalTo(self) }
        
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
        
        circleView.cornerRadius = 104
        circleView.setBorder(color: Color.orange, width: 2)
        insertSubview(circleView, belowSubview: avatarView)
        circleView.snp_makeConstraints { (make) in
            make.center.equalTo(avatarView)
            make.size.equalTo(208)
        }
        
        layoutNameAndInfoLabels()
        
        avatarView.user = user
        nameLabel.text = user.name
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient, withOptions: [])
        _ = try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        if call.direction == .Incoming {
            _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.Speaker)
            startPlayingSound("incoming", loop: true)
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
            
            if !isVideo {
                startAcceptButtonAnimation()
                startCallAnimation()
                acceptButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.acceptButtonPanning(_:))))
            }
            
        } else {
            _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(isVideo ? .Speaker : .None)
            microphoneButton.active = false
            speakerButton.active = false
            infoLabel.text = "waiting_for_response".ls
            self.add(declineButton, {
                $0.bottom.equalTo(self).offset(-20)
                $0.centerX.equalTo(self)
                $0.size.equalTo(74)
            })
        }
        
        if isVideo {
            if let localVideoView = videoController.localView() {
                videoController.captureDevicePosition = .Front
                let localVideoContainer = UIView()
                localVideoContainer.backgroundColor = UIColor.blackColor()
                add(localVideoContainer, { (make) in
                    make.top.equalTo(self).offset(25)
                    make.leading.equalTo(self).offset(5)
                    make.width.equalTo(self).multipliedBy(0.25)
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
        
        if !isVideo {
            add(speakerButton) { (make) in
                make.centerY.equalTo(declineButton)
                make.centerX.equalTo(self).multipliedBy(0.5).offset(-19)
                make.size.equalTo(44)
            }
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
        redialButton.addTarget(self, action: #selector(self.redial(_:)), forControlEvents: .TouchUpInside)
        closeButton.addTarget(self, action: #selector(self.close(_:)), forControlEvents: .TouchUpInside)
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
            insertSubview(arrow, belowSubview: acceptButton)
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
    
    private lazy var spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
    
    func accept(sender: UIButton) {
        user.p2pWrap?.updateCallDate(nil)
        acceptButton.hidden = true
        spinner.color = Color.orange
        add(spinner) { (make) in
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
            self.alpha = 0
            }, completion: { (_) in
                self.close()
        })
    }
    
    func toggleCamera(sender: UIButton) {
        videoController.captureDevicePosition = SINToggleCaptureDevicePosition(videoController.captureDevicePosition)
    }
    
    private static weak var previousCallView: CallView?
    
    static var isVisible: Bool {
        return previousCallView?.superview != nil
    }
    
    func present() {
        UIWindow.mainWindow.endEditing(true)
        CallView.previousCallView?.removeFromSuperview()
        CallView.previousCallView = self
        let view = UIWindow.mainWindow
        view.add(self) { $0.edges.equalTo(view) }
        setupSubviews()
    }
    
    func callDidProgress(call: SINCall!) {
        startPlayingSound("ringback", loop: true)
    }
    
    private weak var topVideoView: UIView?
    private weak var bottomVideoView: UIView?
    
    func callDidEstablish(call: SINCall!) {
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: [])
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        if isVideo {
            _ = try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.Speaker)
        }
        stopPlayingSound()
        speakerButton.hidden = false
        microphoneButton.hidden = false
        acceptButton.loading = false
        spinner.removeFromSuperview()
        acceptButton.removeFromSuperview()
        declineButton.cornerRadius = 37
        microphoneButton.active = true
        speakerButton.active = true
        microphoneButton.selected = true
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
        
        if isVideo {
            
            blurView.hidden = true
            avatarView.hidden = true
            logoView.hidden = true
            circleView.hidden = true
            
            backgroundColor = UIColor.blackColor()
            
            let topVideoView = UIView()
            
            self.topVideoView = topVideoView
            
            topVideoView.backgroundColor = UIColor(white: 0, alpha: 0.75)
            
            add(topVideoView, { (make) in
                make.leading.top.trailing.equalTo(self)
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
            
            add(bottomVideoView, { (make) in
                make.leading.bottom.trailing.equalTo(self)
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
                addSubview(localVideoView)
                localVideoView.snp_remakeConstraints { (make) in
                    make.leading.equalTo(self).offset(5)
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
                make.bottom.equalTo(self).offset(-20)
                make.centerX.equalTo(self)
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
                    make.leading.trailing.equalTo(self)
                    make.bottom.equalTo(self.snp_top).offset(20)
                } else {
                    make.leading.top.trailing.equalTo(self)
                }
            })
            bottomVideoView.snp_remakeConstraints(closure: { (make) in
                if hidden {
                    make.leading.trailing.equalTo(self)
                    make.top.equalTo(self.snp_bottom)
                } else {
                    make.leading.bottom.trailing.equalTo(self)
                }
            })
            self.layoutIfNeeded()
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
        removeFromSuperview()
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
        addSubview(nameLabel)
        nameLabel.snp_remakeConstraints {
            $0.top.equalTo(avatarView.snp_bottom).offset(20)
            $0.centerX.equalTo(self)
            $0.leading.lessThanOrEqualTo(self).offset(12)
            $0.trailing.lessThanOrEqualTo(self).offset(-12)
        }
        addSubview(infoLabel)
        infoLabel.snp_remakeConstraints {
            $0.top.equalTo(nameLabel.snp_bottom).offset(20)
            $0.centerX.equalTo(self)
            $0.leading.lessThanOrEqualTo(self).offset(12)
            $0.trailing.lessThanOrEqualTo(self).offset(-12)
        }
    }
    
    private func endCall(reason: String?) {
        if isVideo {
            videoController.captureDevicePosition = .Front
            if topVideoView != nil {
                backgroundColor = UIColor.clearColor()
                topVideoView?.removeFromSuperview()
                bottomVideoView?.removeFromSuperview()
                remoteVideoView?.removeFromSuperview()
                layoutNameAndInfoLabels()
                blurView.hidden = false
                avatarView.hidden = false
                logoView.hidden = false
                circleView.hidden = false
            }
            localVideoView?.removeFromSuperview()
        }
        updateTimerBlock = nil
        stopPlayingSound()
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient, withOptions: [])
        _ = try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        startPlayingSound("hangup", loop: false)
        if let reason = reason {
            infoLabel.text = reason
            infoLabel.textColor = Color.grayLighter
            microphoneButton.hidden = true
            speakerButton.hidden = true
            declineButton.hidden = true
            self.add(redialButton, {
                $0.bottom.equalTo(self).offset(-20)
                $0.centerX.equalTo(self).multipliedBy(1.5)
                $0.size.equalTo(74)
            })
            self.add(closeButton, {
                $0.bottom.equalTo(self).offset(-20)
                $0.centerX.equalTo(self).multipliedBy(0.5)
                $0.size.equalTo(74)
            })
        } else {
            animationViews?.all({ $0.removeFromSuperview() })
            infoLabel.text = "call_ended".ls
            infoLabel.textColor = Color.grayLighter
            userInteractionEnabled = false
            microphoneButton.hidden = true
            speakerButton.hidden = true
            acceptButton.hidden = true
            declineButton.hidden = true
            redialButton.hidden = true
            closeButton.hidden = true
            UIView.animateWithDuration(0.5, delay: 1.5, options:[], animations: {
                self.alpha = 0
                }, completion: { (_) in
                    self.close()
            })
        }
    }
    
    func callDidAddVideoTrack(call: SINCall!) {
        if let remoteVideoView = videoController.remoteView() {
            layoutIfNeeded()
            addSubview(remoteVideoView)
            self.remoteVideoView = remoteVideoView
            remoteVideoView.contentMode = .ScaleAspectFill
            sendSubviewToBack(remoteVideoView)
            remoteVideoView.tapped({ [weak self] (_) in
                self?.setVideoViewsHidden(self?.topVideoView?.frame.origin.y == 0)
                })
        }
    }
}