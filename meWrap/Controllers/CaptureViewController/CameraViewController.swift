//
//  CameraViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import AVFoundation

class CameraView: UIView {
    
    override var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }
    
    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
}

protocol CameraViewControllerDelegate: AssetsViewControllerDelegate {
    func cameraViewController(controller: CameraViewController, didCaptureImage image: UIImage, saveToAlbum: Bool)
    func cameraViewControllerDidCancel(controller: CameraViewController)
    func cameraViewControllerDidFailImageCapturing(controller: CameraViewController)
    func cameraViewControllerWillCaptureImage(controller: CameraViewController)
    func cameraViewController(controller: CameraViewController, didCaptureVideoAtPath path: String, saveToAlbum: Bool)
    func cameraViewControllerDidFinish(controller: CameraViewController)
    func cameraViewControllerCanCaptureMedia(controller: CameraViewController) -> Bool
}

class CameraViewController: BaseViewController {
    
    var handleImageSetup: Block?
    
    weak var delegate: CameraViewControllerDelegate?
    
    var isAvatar = false
    
    var position: AVCaptureDevicePosition {
        set {
            videoInput = AVCaptureDevice.cameraWithPosition(newValue)?.autofocusingCameraInput()
        }
        get {
            return videoInput?.device?.position ?? .Back
        }
    }
    
    var flashMode: AVCaptureFlashMode {
        set {
            videoInput?.device.lock { (device) -> Void in
                if device.isFlashModeSupported(newValue) {
                    device.flashMode = newValue
                }
            }
        }
        get {
            return videoInput?.device?.flashMode ?? .Off
        }
    }
    
    var videoInput: AVCaptureDeviceInput? {
        didSet {
            session.configure { (session) -> Void in
                session.tryRemoveInput(oldValue)
                session.tryAddInput(videoInput)
            }
            flashModeControl.hidden = !(videoInput?.device?.hasFlash ?? false)
            applyDeviceOrientation(DeviceManager.defaultManager.orientation)
        }
    }
    
    lazy var session: CaptureMediaSession = specify(CaptureMediaSession()) {
        $0.addOutput(self.stillImageOutput)
    }
    
    lazy var stillImageOutput: AVCaptureStillImageOutput = specify(AVCaptureStillImageOutput()) {
        $0.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
    }
    
    var zoomScale: CGFloat = 1 {
        didSet {
            if let device = self.videoInput?.device where device.videoZoomFactor != zoomScale {
                device.lock { $0.videoZoomFactor = zoomScale }
            }
        }
    }
    
    let takePhotoButton = Button(preset: .XLarge, weight: .Bold, textColor: UIColor.whiteColor())
    @IBOutlet weak var cropAreaView: UIView?
    internal let cameraView = CameraView()
    internal let photoTakingView = UIView()
    internal let flashModeControl = FlashModeControl()
    internal let rotateButton = Button(icon: "}", size: 18, textColor: UIColor.whiteColor())
    weak var zoomLabel: Label?
    internal let backButton = Button(icon: "w", size: 24, textColor: UIColor.whiteColor())
    
    internal lazy var assetsViewController: AssetsViewController = AssetsViewController(panningView: self.photoTakingView)
    
    private lazy var focusView: UIView = specify(UIView(frame:CGRectMake(0, 0, 67, 67))) {
        $0.userInteractionEnabled = true
        $0.backgroundColor = UIColor.clearColor()
        $0.setBorder(color: Color.orange.colorWithAlphaComponent(0.5))
        $0.userInteractionEnabled = false
    }
    
    deinit {
        VolumeChangeObserver.sharedObserver.unregister()
        DeviceManager.defaultManager.endUsingAccelerometer()
    }
    
    lazy var defaultPosition: AVCaptureDevicePosition = .Back
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.blackColor()
        
        view.add(cameraView) { (make) in
            make.edges.equalTo(view)
        }
        
        view.add(photoTakingView) { (make) in
            make.edges.equalTo(view)
        }
        
        takePhotoButton.addTarget(self, touchUpInside: #selector(self.shot(_:)))
        takePhotoButton.backgroundColor = Color.orange
        takePhotoButton.normalColor = Color.orange
        takePhotoButton.highlightedColor = Color.orangeDark
        takePhotoButton.cornerRadius = 36
        takePhotoButton.setBorder(width: 2)
        view.addSubview(takePhotoButton)
        
        assetsViewController.delegate = delegate
        assetsViewController.isAvatar = isAvatar
        
        photoTakingView.addSubview(assetsViewController.view)
        assetsViewController.view.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(photoTakingView)
            make.bottom.equalTo(takePhotoButton.snp_top).inset(-12)
        }
        
        rotateButton.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        rotateButton.normalColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        rotateButton.highlightedColor = Color.grayLighter
        rotateButton.cornerRadius = 22
        rotateButton.clipsToBounds = true
        rotateButton.setBorder(width: 1)
        rotateButton.exclusiveTouch = true
        rotateButton.addTarget(self, touchUpInside: #selector(self.rotateCamera(_:)))
        photoTakingView.add(rotateButton) { (make) in
            make.trailing.equalTo(photoTakingView).inset(8)
            make.bottom.equalTo(assetsViewController.view.snp_top).inset(-8)
            make.size.equalTo(44)
        }
        
        flashModeControl.backgroundColor = Color.grayDarker.colorWithAlphaComponent(0.7)
        flashModeControl.cornerRadius = 22
        flashModeControl.setBorder(width: 1)
        photoTakingView.add(flashModeControl) { (make) in
            make.leading.equalTo(photoTakingView).inset(8)
            make.bottom.equalTo(assetsViewController.view.snp_top).inset(-8)
        }
        
        backButton.setTitleColor(UIColor.whiteColor().darkerColor(), forState: .Highlighted)
        backButton.addTarget(self, action: #selector(self.cancel(_:)), forControlEvents: .TouchUpInside)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.focusing(_:))))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(self.zooming(_:))))
    }
    
    internal func addCropAreaView() {
        let cropAreaView = UIView()
        cropAreaView.setBorder(color: UIColor(white: 1, alpha: 0.25))
        cropAreaView.clipsToBounds = true
        photoTakingView.insertSubview(cropAreaView, atIndex: 0)
        cropAreaView.snp_makeConstraints { (make) in
            make.leading.trailing.centerY.equalTo(photoTakingView)
            make.height.equalTo(cropAreaView.snp_width)
        }
    }
    
    override func viewDidLoad() {
        
        AudioSession.category = AVAudioSessionCategoryAmbient
        
        super.viewDidLoad()
        
        #if DEBUG
            let samplePhotoButton = DebugButton(type: .System)
            samplePhotoButton.setTitle("Sample", forState: .Normal)
            samplePhotoButton.addTarget(self, touchUpInside: #selector(self.getSamplePhoto(_:)))
            photoTakingView.add(samplePhotoButton) {
                $0.centerX.equalTo(photoTakingView)
                $0.bottom.equalTo(assetsViewController.view.snp_top).inset(-20)
            }
        #endif
        
        DeviceManager.defaultManager.subscribe(self) { [unowned self] orientation in
            self.applyDeviceOrientation(orientation)
        }
        DeviceManager.defaultManager.beginUsingAccelerometer()
        
        AVCaptureDevice.authorize({ _ in
            self.position = self.defaultPosition
            if self.isAvatar {
                self.flashMode = .Off
            } else {
                self.flashMode = NSUserDefaults.standardUserDefaults().captureMediaFlashMode
            }
            self.flashModeControl.mode = self.flashMode
            self.cameraView.layer.session = self.session
            self.session.start()
            self.cameraView.setNeedsLayout()
            }) { _ in
                let accessLabel = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
                accessLabel.text = "access_to_camera_message".ls
                self.cameraView.add(accessLabel) { (make) in
                    make.center.equalTo(self.cameraView)
                }
                self.takePhotoButton.active = false
        }
        
        UIAlertController.showNoMediaAccess(!isAvatar)
    }
    
    override func shouldUsePreferredViewFrame() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        assetsViewController.enqueueAutoHide()
        registerOnVolumeChange()
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        VolumeChangeObserver.sharedObserver.unregister()
        assetsViewController.cancelAutoHide()
        UIApplication.sharedApplication().idleTimerDisabled = false
    }
    
    internal func registerOnVolumeChange() {
        let observer = VolumeChangeObserver.sharedObserver
        observer.locked = false
        observer.registerWithBlock { [weak self] _ in
            if let controller = self where controller.canCaptureMedia() == true {
                observer.locked = true
                controller.captureImage({ () -> Void in
                    if !controller.isAvatar {
                        self?.handleImageSetup = {
                             observer.locked = false
                        }
                    }
                })
            }
        }
    }
    
    private func finishWithImage(image: UIImage) {
        delegate?.cameraViewController(self, didCaptureImage: image, saveToAlbum: true)
    }
    
    private func captureImage(completon: Block?) {
        delegate?.cameraViewControllerWillCaptureImage(self)
        assetsViewController.setHidden(true, animated: true)
        self.takePhotoButton.active = false
        view.userInteractionEnabled = false
        UIView.animateWithDuration(0.1, animations: { self.cameraView.alpha = 0.0 }) { _ in
            UIView.animateWithDuration(0.1, animations: {  self.cameraView.alpha = 1.0 })
        }
        captureImage({ (image) -> Void in
            self.finishWithImage(image)
            self.takePhotoButton.active = true
            self.view.userInteractionEnabled = true
            completon?()
            }) { (error) -> Void in
                error?.show()
                self.takePhotoButton.active = true
                self.view.userInteractionEnabled = true
                completon?()
        }
    }
    
    internal func canCaptureMedia() -> Bool {
        return delegate?.cameraViewControllerCanCaptureMedia(self) ?? true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    private func applyDeviceOrientation(orientation: UIDeviceOrientation) {
        if orientation != .Unknown {
            stillImageOutput.videoConnection()?.applyDeviceOrientation(orientation)
            applyDeviceOrientationToFunctionalButton(orientation)
        }
    }
    
    private func applyDeviceOrientationToFunctionalButton(orientation: UIDeviceOrientation) {
        animate {
            animateOrientationChange(orientation.interfaceTransform())
        }
    }
    
    internal func animateOrientationChange(transform: CGAffineTransform) {
        backButton.transform = transform
        rotateButton.transform = transform
        takePhotoButton.transform = transform
        for subView in flashModeControl.buttons {
            subView.transform = transform
        }
    }
    
    private func autoFocusAndExposureAtPoint(point: CGPoint) {
        videoInput?.device.lock({ $0.concentrateOn(cameraView.layer.captureDevicePointOfInterestForPoint(point)) })
    }
    
    private func fetchSampleImage(result: UIImage -> Void, failure: FailureBlock) {
        Dispatch.defaultQueue.fetch({ () -> UIImage? in
            let width = UIScreen.mainScreen().bounds.size.width
            let size = CGSizeMake(width, width / 0.75)
            let url = "http://placeimg.com/\(Int(size.width))/\(Int(size.height))/any"
            guard let data = NSData(contentsOfURL:url.URL!) else { return nil }
            return UIImage(data: data)
            }) { (object) -> Void in
                if let image = object {
                    result(image)
                } else {
                    failure(nil)
                }
        }
    }
    
    private func captureImage(result: UIImage -> Void, failure: FailureBlock) {
        #if TARGET_OS_SIMULATOR
            fetchSampleImage(result, failure: failure)
            return
        #endif
        
        let handler: (CMSampleBufferRef?, NSError?) -> Void = { (buffer, error) in
            if let buffer = buffer,
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                let image = UIImage(data:imageData) {
                    result(image)
            } else {
                failure(error)
            }
        }
        
        session.performBlock {
            Dispatch.mainQueue.async {
                let output = self.stillImageOutput
                if let connection = output.videoConnection() where self.session.containsOutput(output) {
                    connection.videoMirrored = (self.position == .Front)
                    output.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: handler)
                } else {
                    failure(nil)
                }
            }
        }
    }
}

extension CameraViewController { // MARK: - Actions
    
    @IBAction func cancel(sender: AnyObject?) {
        delegate?.cameraViewControllerDidCancel(self)
    }
    
    @IBAction func shot(sender: AnyObject?) {
        if canCaptureMedia() {
            captureImage(nil)
        }
    }
    
    @IBAction func getSamplePhoto(sender: AnyObject?) {
        self.takePhotoButton.active = false
        fetchSampleImage({ (image) -> Void in
            self.delegate?.cameraViewController(self, didCaptureImage:image, saveToAlbum:false)
            self.takePhotoButton.active = true
            }) { _ in
                self.takePhotoButton.active = true
        }
    }
    
    @IBAction func flashModeChanged(sender: FlashModeControl) {
        let flashMode = sender.mode
        videoInput?.device.lock({ (device) -> Void in
            if device.isFlashModeSupported(flashMode) {
                device.flashMode = flashMode
                if !isAvatar {
                    NSUserDefaults.standardUserDefaults().captureMediaFlashMode = flashMode
                }
            } else {
                sender.mode = device.flashMode
            }
        })
    }
    
    @IBAction func rotateCamera(sender: AnyObject?) {
        position = position == .Back ? .Front : .Back
        flashMode = flashModeControl.mode
        zoomScale = 1
        if !isAvatar && position != .Unspecified {
            NSUserDefaults.standardUserDefaults().captureMediaDevicePosition = position
        }
    }
    
    @IBAction func focusing(sender: UITapGestureRecognizer) {
        guard session.running else { return }
        let point = sender.locationInView(cameraView)
        autoFocusAndExposureAtPoint(point)
        focusView.center = point
        cameraView.addSubview(focusView)
        self.focusView.alpha = 1.0
        UIView.animateWithDuration(0.33, delay: 1.0, options: .CurveEaseInOut, animations: {
            self.focusView.alpha = 0.0
            }) { _ in }
    }
    
    @IBAction func zooming(sender: UIPinchGestureRecognizer) {
        if sender.state == .Began {
            let zoomLabel = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
            zoomLabel.text = "\(Int(zoomScale))x"
            view.add(zoomLabel, { (make) in
                make.trailing.equalTo(view).inset(8)
                make.bottom.equalTo(takePhotoButton.snp_top).inset(-12)
            })
            self.zoomLabel = zoomLabel
        } else if sender.state == .Changed {
            let device = self.videoInput?.device
            zoomScale = smoothstep(1, min(8, device?.activeFormat?.videoMaxZoomFactor ?? 1), zoomScale * sender.scale)
            sender.scale = 1
            zoomLabel?.text = "\(Int(zoomScale))x"
        } else if sender.state == .Ended || sender.state == .Cancelled {
            weak var zoomLabel = self.zoomLabel
            UIView.animateWithDuration(0.5, animations: {
                zoomLabel?.alpha = 0
                }, completion: { (_) in
                    zoomLabel?.removeFromSuperview()
            })
        }
    }
}

extension CameraViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer where recognizer.view == view {
            let velocity = recognizer.velocityInView(view)
            return abs(velocity.y) > abs(velocity.x)
        } else {
            return true
        }
    }
}

extension AVCaptureDevice {
    class func authorize( success: Block, failure: FailureBlock) {
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if status == .Authorized {
            success()
        } else if status.denied {
            failure(nil)
        } else {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted) -> Void in
                Dispatch.mainQueue.async({ _ in
                    if (granted) {
                        success()
                    } else {
                        failure(nil)
                    }
                })
            })
        }
    }
}
