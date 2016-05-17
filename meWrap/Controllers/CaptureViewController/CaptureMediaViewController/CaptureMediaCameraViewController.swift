//
//  CaptureMediaCameraViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class VideoRecordControl: UIView {
    
    let cancelLabel = Label(icon: "!", size: 20, textColor: Color.orange)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.5)
        let circleView = UIView()
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
        
        let arrowLabel = Label(icon: "w", size: 15, textColor: Color.orange)
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
        layer.mask = mask
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CaptureMediaCameraViewController: CameraViewController, CaptureWrapContainer {

    @IBOutlet weak var finishButton: Button?
    
    @IBOutlet weak var videoRecordingProgressBar: ProgressBar!
    @IBOutlet weak var videoRecordingView: UIView!
    @IBOutlet weak var videoRecordingTimeLabel: UILabel?
    lazy var videoRecordControl: VideoRecordControl = VideoRecordControl()
    @IBOutlet weak var videoRecordingIndicator: UIView?
    weak var videoRecordingTimer: NSTimer?
    weak var startVideoRecordingTimer: NSTimer?
    weak var audioInput: AVCaptureDeviceInput?
    var videoRecordingCancelled: Bool = false
    var videoRecordingTimeLeft: NSTimeInterval = Constants.maxVideoRecordedDuration
    
    lazy var movieFileOutput: AVCaptureMovieFileOutput = specify(AVCaptureMovieFileOutput()) {
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
        if videoFilePath.isExistingFilePath {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(self.videoFilePath)
        }
    }
    
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
    
    weak var wrapView: WrapView?
    
    var changeWrap: (Void -> Void)?
        
    @IBAction func selectWrap(sender: UIButton) {
        changeWrap?()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWrapView(wrap)
        let recognizer = UILongPressGestureRecognizer(target:self, action:#selector(CaptureMediaCameraViewController.startVideoRecording(_:)))
        recognizer.allowableMovement = takePhotoButton.width
        recognizer.delegate = self
        takePhotoButton.addGestureRecognizer(recognizer)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Photo, inProgress: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Photo, inProgress: false)
    }
    
    internal func updateVideoRecordingViews(recording: Bool) {
        bottomView.hidden = recording
        assetsView.hidden = recording
        assetsInteractionView.hidden = recording
        rotateButton.hidden = recording
        cropAreaView?.hidden = recording
        flashModeControl.alpha = recording ? 0.0 : 1.0
        wrapView?.superview?.hidden = recording
    }
    
    func startVideoRecording() {
        self.videoRecordingCancelled = false
        if videoFilePath.isExistingFilePath {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(videoFilePath)
        }
        if let url = videoFilePath.fileURL where session.containsOutput(movieFileOutput) {
            movieFileOutput.startRecordingToOutputFileURL(url, recordingDelegate: self)
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
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Video, inProgress: true)
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
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Photo, inProgress: true)
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
            movieFileOutput.stopRecording()
        } else {
            if bottomView.hidden {
                prepareSessionForPhotoTaking()
                updateVideoRecordingViews(false)
            }
            startVideoRecordingTimer?.invalidate()
            startVideoRecordingTimer = nil
        }
        prepareSessionForPhotoTaking()
    }
    
    func cancelVideoRecording() {
        videoRecordingCancelled = true
        stopVideoRecording()
    }
    
    @IBAction func startVideoRecording(sender: UILongPressGestureRecognizer) {
        guard canCaptureMedia() else { return }
        
        switch sender.state {
        case .Began:
            updateVideoRecordingViews(true)
            prepareSessionForVideoRecording {
                self.startVideoRecordingTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(CaptureMediaCameraViewController.startVideoRecording as (CaptureMediaCameraViewController) -> () -> ()), userInfo: nil, repeats: false)
            }
        case .Changed:
            let location = sender.locationInView(videoRecordingView)
            if movieFileOutput.recording && !videoRecordingCancelled {
                if location.x < videoRecordControl.x + videoRecordControl.cancelLabel.width {
                    cancelVideoRecording()
                }
            }
        case .Ended:
            let location = sender.locationInView(videoRecordingView)
            if location.x < videoRecordControl.x + videoRecordControl.cancelLabel.width {
                if !videoRecordingCancelled {
                    cancelVideoRecording()
                }
            } else {
                stopVideoRecording()
            }
        default: break
        }
    }
    
    @IBAction func finish(sender: AnyObject?) {
        delegate?.cameraViewControllerDidFinish?(self)
    }
    
    override func animateOrientationChange(transform: CGAffineTransform) {
        super.animateOrientationChange(transform)
        videoRecordingTimeLabel?.transform = transform
        finishButton?.transform = transform
    }
}

private let videoRecordingTimerInterval: NSTimeInterval = 0.03333333

extension CaptureMediaCameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        videoRecordingIndicator?.layer.removeAnimationForKey("videoRecording")
        videoRecordingTimer?.invalidate()
        prepareSessionForPhotoTaking()
        updateVideoRecordingViews(false)
        videoRecordingView.hidden = true
        videoRecordControl.removeFromSuperview()
        takePhotoButton.hidden = false
        if videoRecordingCancelled || (error != nil && error.code != AVError.MaximumDurationReached.rawValue) {
            error?.show()
            _ = try? NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
        } else {
            delegate?.cameraViewController?(self, didCaptureVideoAtPath: videoFilePath, saveToAlbum: true)
        }
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        videoRecordingIndicator?.layer.addAnimation(specify(CABasicAnimation(keyPath: "opacity"), {
            $0.fromValue = 1
            $0.toValue = 0
            $0.autoreverses = true
            $0.duration = 0.5
            $0.repeatCount = FLT_MAX
            $0.removedOnCompletion = false
        }), forKey: "videoRecording")
        videoRecordingView.add(videoRecordControl) { (make) in
            make.trailing.centerY.equalTo(takePhotoButton)
        }
        takePhotoButton.hidden = true
        videoRecordingTimeLeft = Constants.maxVideoRecordedDuration
        videoRecordingTimeLabel?.text = String(Constants.maxVideoRecordedDuration)
        videoRecordingProgressBar.progress = 0;
        videoRecordingView.hidden = false
        videoRecordingTimer?.invalidate()
        videoRecordingTimer = NSTimer.scheduledTimerWithTimeInterval(videoRecordingTimerInterval, target: self, selector: #selector(self.recordingTimerChanged(_:)), userInfo: nil, repeats: true)
    }
    
    func recordingTimerChanged(timer: NSTimer) {
        if videoRecordingTimeLeft > 0 {
            videoRecordingTimeLeft = max(0, videoRecordingTimeLeft - videoRecordingTimerInterval)
            videoRecordingTimeLabel?.text = String(ceil(videoRecordingTimeLeft)) + "\""
            videoRecordingProgressBar.progress = CGFloat(1.0 - videoRecordingTimeLeft/Constants.maxVideoRecordedDuration)
        } else {
            videoRecordingTimer?.invalidate()
        }
    }
}
