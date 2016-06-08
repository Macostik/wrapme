//
//  CandyCameraViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation

final class VideoRecordControl: UIView {
    
    let cancelLabel = Label(icon: "!", size: 20, textColor: Color.orange)
    
    private let arrowLabel = Label(icon: "w", size: 15, textColor: Color.orange)
    
    private let backgroundView = UIView()
    
    private let circleView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundView.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.5)
        
        add(backgroundView) { (make) in
            make.edges.equalTo(self)
        }
        
        circleView.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.9)
        circleView.cornerRadius = 36
        add(circleView) { (make) in
            make.size.equalTo(72)
            make.trailing.top.bottom.equalTo(self)
        }
        circleView.add(specify(UIView(), {
            $0.cornerRadius = 16
            $0.backgroundColor = Color.dangerRed
        })) { (make) in
            make.size.equalTo(32)
            make.center.equalTo(circleView)
        }
        
        arrowLabel.textAlignment = .Center
        add(arrowLabel) { (make) in
            make.width.equalTo(22)
            make.centerY.equalTo(self)
            make.trailing.equalTo(circleView.snp_leading)
        }
        
        cancelLabel.cornerRadius = 28
        cancelLabel.clipsToBounds = true
        cancelLabel.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.9)
        cancelLabel.textAlignment = .Center
        add(cancelLabel) { (make) in
            make.size.equalTo(56)
            make.leading.centerY.equalTo(self)
            make.trailing.equalTo(arrowLabel.snp_leading)
        }
        bringSubviewToFront(circleView)
        layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let mask = CAShapeLayer()
        let path = UIBezierPath()
        path.move(cancelLabel.width/2 ^ cancelLabel.frame.maxY)
        path.addArcWithCenter(cancelLabel.width/2 ^ height/2, radius: cancelLabel.width/2, startAngle: CGFloat(M_PI_2), endAngle: -CGFloat(M_PI_2), clockwise: true)
        path.addLineToPoint((width - height/2) ^ 0)
        path.addArcWithCenter((width - height/2) ^ height/2, radius: height/2, startAngle: -CGFloat(M_PI_2), endAngle: CGFloat(M_PI_2), clockwise: true)
        path.closePath()
        mask.path = path.CGPath
        backgroundView.layer.mask = mask
    }
    
    func expand(animated: Bool, completion: (() -> ())? = nil) {
        
        animate(animated, duration: 0.3) {
            UIView.setAnimationCurve(.EaseOut)
            cancelLabel.transform = CGAffineTransformIdentity
        }
        animate(animated, duration: 0.2) {
            UIView.setAnimationDelay(0.2)
            backgroundView.alpha = 1
        }
        if animated {
            UIView.animateWithDuration(0.2, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6, options: .CurveEaseOut, animations: {
                self.arrowLabel.transform = CGAffineTransformIdentity
            }) { (_) in
                completion?()
            }
        } else {
            arrowLabel.transform = CGAffineTransformIdentity
            completion?()
        }
    }
    
    func collapse(animated: Bool, completion: (() -> ())? = nil) {
        
        animate(animated, duration: 0.1) {
            backgroundView.alpha = 0
            arrowLabel.transform = CGAffineTransformMakeTranslation(max(0, circleView.center.x - arrowLabel.center.x), 0)
        }
        var transform = CGAffineTransformMakeTranslation(max(0, self.circleView.center.x - self.cancelLabel.center.x), 0)
        transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
        if animated {
            UIView.animateWithDuration(0.2, delay: 0.1, options: .CurveEaseIn, animations: {
                
                self.cancelLabel.transform = transform
            }) { (_) in
                completion?()
            }
        } else {
            cancelLabel.transform = transform
            completion?()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MediaCameraViewController: CameraViewController {
    
    var startVideoRecordingTask: DispatchTask?
    weak var audioInput: AVCaptureDeviceInput?
    var videoRecordingCancelled: Bool = false
    
    lazy var movieFileOutput: CaptureMovieFileOutput = specify(CaptureMovieFileOutput()) {
        let maxDuration = CMTimeMakeWithSeconds(Constants.maxVideoRecordedDuration, Int32(NSEC_PER_SEC))
        $0.maxRecordedDuration = maxDuration
        $0.movieFragmentInterval = kCMTimeInvalid
    }
    
    lazy var videoFilePath: String = {
        let path = "Documents/Videos"
        _ = try? NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories:true, attributes:nil)
        return "\(path)/capturedVideo.mov"
    }()
    
    deinit {
        AudioSession.locked = false
        AudioSession.category = AVAudioSessionCategoryAmbient
        if videoFilePath.isExistingFilePath {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(self.videoFilePath)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AudioSession.category = AVAudioSessionCategoryPlayAndRecord
        AudioSession.locked = true
        let recognizer = UILongPressGestureRecognizer(target:self, action:#selector(self.startVideoRecording(_:)))
        recognizer.allowableMovement = 72
        recognizer.delegate = self
        takePhotoButton.addGestureRecognizer(recognizer)
    }
    
    func startVideoRecording() {
        self.videoRecordingCancelled = false
        if videoFilePath.isExistingFilePath {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(videoFilePath)
        }
        if let url = videoFilePath.fileURL where session.containsOutput(movieFileOutput) {
            movieFileOutput.start(url, handler: { [weak self] (output) in
                self?.didStartVideoRecording(output)
            })
        }
    }
    
    private weak var videoRecordControl: VideoRecordControl?
    
    private func didStartVideoRecording(output: CaptureMovieFileOutput) {
        
        let videoRecordingView = UIView()
        
        view.add(videoRecordingView) { (make) in
            make.edges.equalTo(view)
        }
        
        let videoRecordingProgressBar = specify(ProgressBar()) {
            $0.cornerRadius = 6
            $0.clipsToBounds = true
            $0.backgroundColor = UIColor.blackColor()
            $0.lineWidth = 12
            if let layer = $0.layer as? CAShapeLayer {
                layer.strokeColor = Color.green.CGColor
                layer.lineCap = kCALineCapRound
                layer.lineJoin = kCALineJoinRound
                layer.lineWidth = 12
                layer.cornerRadius = 6
                layer.masksToBounds = true
                layer.backgroundColor = UIColor.blackColor().CGColor
            }
        }
        let videoRecordControl = VideoRecordControl()
        let videoRecordingIndicator = specify(UIView()) {
            $0.cornerRadius = 6
            $0.clipsToBounds = true
            $0.backgroundColor = Color.dangerRed
        }
        
        videoRecordingView.add(videoRecordingProgressBar) {
            $0.centerX.equalTo(videoRecordingView)
            $0.centerY.equalTo(videoRecordingView.snp_top).inset(32)
            $0.size.equalTo(CGSize(width: 200, height: 12))
        }
        videoRecordingView.add(videoRecordingIndicator) {
            $0.leading.equalTo(videoRecordingView).inset(12)
            $0.centerY.equalTo(videoRecordingView.snp_top).inset(32)
            $0.size.equalTo(12)
        }
        videoRecordingIndicator.addAnimation(specify(CABasicAnimation(keyPath: "opacity"), {
            $0.fromValue = 1
            $0.toValue = 0
            $0.autoreverses = true
            $0.duration = 0.5
            $0.repeatCount = FLT_MAX
            $0.removedOnCompletion = false
        }))
        videoRecordingView.add(videoRecordControl) { (make) in
            make.trailing.centerY.equalTo(takePhotoButton)
        }
        videoRecordControl.layoutIfNeeded()
        videoRecordControl.collapse(false)
        videoRecordControl.expand(true)
        takePhotoButton.hidden = true
        videoRecordingProgressBar.progress = 0
        self.videoRecordControl = videoRecordControl
        
        session.performBlock { () in
            while self.movieFileOutput.recording {
                let duration = CMTimeGetSeconds(self.movieFileOutput.recordedDuration)
                let time = CMTimeGetSeconds(self.movieFileOutput.maxRecordedDuration)
                let progress = CGFloat(duration / time)
                Dispatch.mainQueue.async({ () in
                    videoRecordingProgressBar.progress = progress
                })
            }
        }
        
        output.finishHandler = { outputURL, error in
            videoRecordControl.collapse(true) {
                self.prepareSessionForPhotoTaking()
                self.photoTakingView.hidden = false
                videoRecordingView.removeFromSuperview()
                self.takePhotoButton.hidden = false
                if self.videoRecordingCancelled || (error != nil && error?.code != AVError.MaximumDurationReached.rawValue) {
                    if let url = outputURL {
                        _ = try? NSFileManager.defaultManager().removeItemAtURL(url)
                    }
                } else {
                    self.delegate?.cameraViewController(self, didCaptureVideoAtPath: self.videoFilePath, saveToAlbum: true)
                }
            }
        }
    }
    
    private func blurCamera(handler: (completion: Void -> Void) -> Void) {
        let snapshot = cameraView.superview!.snapshotViewAfterScreenUpdates(true)
        snapshot.frame = cameraView.superview!.bounds
        snapshot.alpha = 0
        cameraView.superview!.insertSubview(snapshot, aboveSubview: cameraView)
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style:.Light))
        effectView.frame = snapshot.bounds
        snapshot.addSubview(effectView)
        UIView.animateWithDuration(0.2, animations: { snapshot.alpha = 1 })
        handler(completion: {
            UIView.animateWithDuration(0.2, animations: { snapshot.alpha = 0 }, completion: { _ in
                snapshot.removeFromSuperview()
            })
        })
    }
    
    private func prepareSessionForVideoRecording(preparingCompletion: Block) {
        VolumeChangeObserver.sharedObserver.unregister()
        if !session.containsOutput(movieFileOutput) {
            blurCamera({ (completion) -> Void in
                self.session.performBlock({ _ in
                    self.configureVideoOutput()
                    Dispatch.mainQueue.async {
                        self.movieFileOutput.videoConnection()?.applyDeviceOrientation(DeviceManager.defaultManager.orientation)
                        completion()
                        preparingCompletion()
                    }
                })
            })
        }
    }
    
    private func configureVideoOutput() {
        guard let device = self.videoInput?.device else { return }
        let torchMode = AVCaptureTorchMode(rawValue: self.flashMode.rawValue) ?? .Off
        let activeFormat = device.formatWithRatio(16.0/9.0)
        session.configure({ _ in
            let input = AVCaptureDevice.microphone()?.input()
            session.tryAddInput(input)
            self.audioInput = input
            session.removeOutput(stillImageOutput)
            session.tryAddOutput(movieFileOutput)
            session.sessionPreset = activeFormat != nil ? AVCaptureSessionPresetInputPriority : AVCaptureSessionPresetMedium
        })
        device.lock { device in
            if let format = activeFormat {
                device.activeFormat = format
            }
            
            device.videoZoomFactor = smoothstep(1, min(8, device.activeFormat.videoMaxZoomFactor), zoomScale)
            device.setSupportedFocusMode(.ContinuousAutoFocus)
            if device.hasTorch && device.torchAvailable && device.isTorchModeSupported(torchMode) {
                device.torchMode = torchMode
            }
        }
    }
    
    private func prepareSessionForPhotoTaking() {
        registerOnVolumeChange()
        let output = stillImageOutput
        if !session.containsOutput(output) {
            self.takePhotoButton.userInteractionEnabled = false
            blurCamera({ (completion) -> Void in
                self.session.configure({ (session) -> Void in
                    session.sessionPreset = AVCaptureSessionPresetPhoto
                    session.tryRemoveInput(self.audioInput)
                    session.tryRemoveOutput(self.movieFileOutput)
                    session.tryAddOutput(output)
                    }, completion: {
                        self.videoInput?.device.lock({ (device) -> Void in
                            device.videoZoomFactor = smoothstep(1, min(8, device.activeFormat.videoMaxZoomFactor), self.zoomScale)
                            device.setSupportedFocusMode(.AutoFocus)
                            if device.isTorchModeSupported(.Off) {
                                device.torchMode = .Off
                            }
                        })
                        output.videoConnection()?.applyDeviceOrientation(DeviceManager.defaultManager.orientation)
                        self.takePhotoButton.userInteractionEnabled = true
                        completion()
                })
            })
        }
    }
    
    func stopVideoRecording() {
        if movieFileOutput.recording {
            movieFileOutput.stop({
            })
        } else {
            prepareSessionForPhotoTaking()
            if photoTakingView.hidden {
                self.photoTakingView.hidden = false
            }
            startVideoRecordingTask = nil
        }
    }
    
    func cancelVideoRecording() {
        videoRecordingCancelled = true
        stopVideoRecording()
    }
    
    @IBAction func startVideoRecording(sender: UILongPressGestureRecognizer) {
        guard canCaptureMedia() else { return }
        
        switch sender.state {
        case .Began:
            self.photoTakingView.hidden = true
            prepareSessionForVideoRecording {
                self.startVideoRecordingTask = DispatchTask(0.5, { [weak self] _ in
                    self?.startVideoRecording()
                })
            }
        case .Changed:
            let location = sender.locationInView(videoRecordControl)
            if movieFileOutput.recording && !videoRecordingCancelled {
                if location.x < videoRecordControl?.cancelLabel.frame.maxX {
                    cancelVideoRecording()
                }
            }
        case .Ended:
            let location = sender.locationInView(videoRecordControl)
            if location.x < videoRecordControl?.cancelLabel.frame.maxX {
                if !videoRecordingCancelled {
                    cancelVideoRecording()
                }
            } else {
                stopVideoRecording()
            }
        default: break
        }
    }
}

class CandyCameraViewController: MediaCameraViewController, CaptureWrapContainer {
    
    let finishButton = Button(preset: .Large, weight: .Bold, textColor: Color.orange)
    
    weak var wrap: Wrap? {
        didSet {
            if viewAppeared {
                NotificationCenter.defaultCenter.setActivity(oldValue, type: .Photo, inProgress: false)
            }
            
            if isViewLoaded() {
                setupWrapView(wrap)
            }
            
            if viewAppeared {
                NotificationCenter.defaultCenter.setActivity(wrap, type: .Photo, inProgress: true)
            }
        }
    }
    
    var wrapView = WrapView()
    
    var changeWrap: (Void -> Void)?
    
    @IBAction func selectWrap(sender: UIButton) {
        changeWrap?()
    }
    
    override func loadView() {
        super.loadView()
        
        let bottomGradient = GradientView(startColor: UIColor.blackColor(), contentMode: .Bottom)
        photoTakingView.insertSubview(bottomGradient, atIndex: 0)
        bottomGradient.snp_makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(photoTakingView)
            make.height.equalTo(48)
        }
        
        let videoTip = Label(preset: .Smaller, weight: .Regular, textColor: UIColor.whiteColor())
        videoTip.text = "video_suggestion".ls
        photoTakingView.add(videoTip) { (make) in
            make.centerX.equalTo(photoTakingView)
            make.bottom.equalTo(photoTakingView).inset(14)
        }
        
        takePhotoButton.snp_makeConstraints { (make) in
            make.size.equalTo(72)
            make.centerX.equalTo(view)
            make.bottom.equalTo(videoTip.snp_top).inset(-14)
        }
        
        finishButton.setTitle("next".ls, forState: .Normal)
        finishButton.addTarget(self, touchUpInside: #selector(self.finish(_:)))
        photoTakingView.add(finishButton) { (make) in
            make.trailing.equalTo(photoTakingView).inset(8)
            make.centerY.equalTo(takePhotoButton)
        }
        
        addCropAreaView()
        
        let topGradient = GradientView(startColor: UIColor.blackColor(), contentMode: .Top)
        photoTakingView.insertSubview(topGradient, atIndex: 0)
        topGradient.snp_makeConstraints { (make) in
            make.leading.trailing.top.equalTo(photoTakingView)
            make.height.equalTo(64)
        }
        
        photoTakingView.add(backButton) { (make) in
            make.centerY.equalTo(topGradient)
            make.leading.equalTo(topGradient).inset(8)
        }
        
        topGradient.add(wrapView) { (make) in
            make.leading.equalTo(backButton.snp_trailing).inset(-12)
            make.top.bottom.equalTo(topGradient)
            make.trailing.lessThanOrEqualTo(topGradient).inset(12)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWrapView(wrap)
        wrapView.selectButton.addTarget(self, touchUpInside: #selector(self.selectWrap(_:)))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Photo, inProgress: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Photo, inProgress: false)
    }
    
    private override func prepareSessionForPhotoTaking() {
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Photo, inProgress: true)
        super.prepareSessionForPhotoTaking()
    }
    
    private override func prepareSessionForVideoRecording(preparingCompletion: Block) {
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Video, inProgress: true)
        super.prepareSessionForVideoRecording(preparingCompletion)
    }
    
    @IBAction func finish(sender: AnyObject?) {
        delegate?.cameraViewControllerDidFinish(self)
    }
    
    override func animateOrientationChange(transform: CGAffineTransform) {
        super.animateOrientationChange(transform)
        finishButton.transform = transform
    }
}
