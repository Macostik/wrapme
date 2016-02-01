//
//  CaptureMediaCameraViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class CaptureMediaCameraViewController: CameraViewController, CaptureWrapContainer {

    @IBOutlet weak var finishButton: WLButton!
    
    @IBOutlet weak var videoRecordingProgressBar: ProgressBar!
    @IBOutlet weak var videoRecordingView: UIView!
    @IBOutlet weak var videoRecordingTimeLabel: UILabel!
    @IBOutlet weak var cancelVideoRecordingLabel: UILabel!
    @IBOutlet weak var videoRecordingIndicator: UIView!
    weak var videoRecordingTimer: NSTimer?
    weak var startVideoRecordingTimer: NSTimer?
    weak var audioInput: AVCaptureDeviceInput?
    var videoRecordingCancelled: Bool = false
    var videoRecordingTimeLeft: NSTimeInterval = Constants.maxVideoRecordedDuration
    
    lazy var videoFilePath: String = {
        let videosDirectoryPath = NSHomeDirectory() + "/Documents/Videos"
        _ = try? NSFileManager.defaultManager().createDirectoryAtPath(videosDirectoryPath, withIntermediateDirectories:true, attributes:nil)
        let path = "\(videosDirectoryPath)/capturedVideo.mov"
        return path
    }()
    
    deinit {
        if videoFilePath.isExistingFilePath {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(self.videoFilePath)
        }
    }
    
    weak var wrap: Wrap? {
        didSet {
            if isViewLoaded() {
                setupWrapView(wrap)
            }
        }
    }
    
    @IBOutlet weak var wrapView: WrapView?
    
    var changeWrap: (Void -> Void)?
        
    @IBAction func selectWrap(sender: UIButton) {
        changeWrap?()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWrapView(wrap)
        let recognizer = UILongPressGestureRecognizer(target:self, action:"startVideoRecording:")
        recognizer.delegate = self
        takePhotoButton.addGestureRecognizer(recognizer)
    }
    
    internal func updateVideoRecordingViews(recording: Bool) {
        bottomView.hidden = recording
        assetsView.hidden = recording
        rotateButton.hidden = recording
        cropAreaView.hidden = recording
        flashModeControl.alpha = recording ? 0.0 : 1.0
        wrapView?.hidden = recording
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
            
            device.videoZoomFactor = Smoothstep(1, min(8, device.activeFormat.videoMaxZoomFactor), zoomScale)
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
                            device.videoZoomFactor = Smoothstep(1, min(8, device.activeFormat.videoMaxZoomFactor), self.zoomScale)
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
                self.startVideoRecordingTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "startVideoRecording", userInfo: nil, repeats: false)
            }
        case .Changed:
            let location = sender.locationInView(videoRecordingView)
            if movieFileOutput.recording && !videoRecordingCancelled {
                if location.x < Constants.screenWidth/4 {
                    cancelVideoRecording()
                }
            }
        case .Ended:
            let location = sender.locationInView(videoRecordingView)
            if cancelVideoRecordingLabel.frame.contains(location) {
                cancelVideoRecording()
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
        videoRecordingTimeLabel.transform = transform
        finishButton.transform = transform
    }
}

private let videoRecordingTimerInterval: NSTimeInterval = 0.03333333

extension CaptureMediaCameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        videoRecordingIndicator.layer.removeAnimationForKey("videoRecording")
        self.cancelVideoRecordingLabel.hidden = true
        videoRecordingTimer?.invalidate()
        prepareSessionForPhotoTaking()
        updateVideoRecordingViews(false)
        videoRecordingView.hidden = true
        if videoRecordingCancelled {
            _ = try? NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
        } else {
            delegate?.cameraViewController?(self, didCaptureVideoAtPath: videoFilePath, saveToAlbum: true)
        }
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.autoreverses = true
        animation.duration = 0.5
        animation.repeatCount = FLT_MAX
        animation.removedOnCompletion = false
        videoRecordingIndicator.layer.addAnimation(animation, forKey: "videoRecording")
        cancelVideoRecordingLabel.hidden = false
        videoRecordingTimeLeft = Constants.maxVideoRecordedDuration
        videoRecordingTimeLabel.text = String(Constants.maxVideoRecordedDuration)
        videoRecordingProgressBar.progress = 0;
        videoRecordingView.hidden = false
        videoRecordingTimer?.invalidate()
        videoRecordingTimer = NSTimer.scheduledTimerWithTimeInterval(videoRecordingTimerInterval, target: self, selector: "recordingTimerChanged:", userInfo: nil, repeats: true)
    }
    
    func recordingTimerChanged(timer: NSTimer) {
        if videoRecordingTimeLeft > 0 {
            videoRecordingTimeLeft = max(0, videoRecordingTimeLeft - videoRecordingTimerInterval)
            videoRecordingTimeLabel.text = String(ceil(videoRecordingTimeLeft)) + "\""
            videoRecordingProgressBar.progress = CGFloat(1.0 - videoRecordingTimeLeft/Constants.maxVideoRecordedDuration)
        } else {
            videoRecordingTimer?.invalidate()
        }
    }
}
