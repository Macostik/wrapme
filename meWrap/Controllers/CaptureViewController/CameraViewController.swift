//
//  CameraViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class CameraView: UIView {
    
    override var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }
    
    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
}

@objc protocol CameraViewControllerDelegate: AssetsViewControllerDelegate {
    optional func cameraViewController(controller: CameraViewController, didCaptureImage image: UIImage, saveToAlbum: Bool)
    optional func cameraViewControllerDidCancel(controller: CameraViewController)
    optional func cameraViewControllerDidFailImageCapturing(controller: CameraViewController)
    optional func cameraViewControllerWillCaptureImage(controller: CameraViewController)
    optional func cameraViewController(controller: CameraViewController, didCaptureVideoAtPath path: String, saveToAlbum: Bool)
    optional func cameraViewControllerDidFinish(controller: CameraViewController)
    optional func cameraViewControllerCanCaptureMedia(controller: CameraViewController) -> Bool
}

class CameraViewController: BaseViewController {
    
    @IBOutlet weak var takePhotoButton: UIButton!
    
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
    
    lazy var session: CaptureMediaSession = {
        let session = CaptureMediaSession()
        session.addOutput(self.stillImageOutput)
        return session
    }()
    
    lazy var movieFileOutput: AVCaptureMovieFileOutput = {
        let output = AVCaptureMovieFileOutput()
        let maxDuration = CMTimeMakeWithSeconds(Constants.maxVideoRecordedDuration, Int32(NSEC_PER_SEC))
        output.maxRecordedDuration = maxDuration
        output.movieFragmentInterval = kCMTimeInvalid
        return output
    }()
    
    lazy var stillImageOutput: AVCaptureStillImageOutput = {
        let output = AVCaptureStillImageOutput()
        output.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        return output
    }()
    
    var zoomScale: CGFloat = 1 {
        didSet {
            if let device = self.videoInput?.device where device.videoZoomFactor != zoomScale {
                device.lock { $0.videoZoomFactor = zoomScale }
                showZoomLabel()
            }
        }
    }
    
    @IBOutlet weak var cropAreaView: UIView?
    @IBOutlet weak var unauthorizedStatusView: UILabel!
    @IBOutlet weak var cameraView: CameraView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var flashModeControl: FlashModeControl!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var assetsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var assetsArrow: UILabel!
    @IBOutlet weak var assetsView: UIView!
    @IBOutlet weak var assetsContentView: UIView!
    @IBOutlet weak var assetsInteractionView: UIView!
    
    internal var assetsViewController = AssetsViewController()
    
    private lazy var focusView: UIView = specify(UIView(frame:CGRectMake(0, 0, 67, 67))) {
        $0.userInteractionEnabled = true
        $0.backgroundColor = UIColor.clearColor()
        $0.borderColor = Color.orange.colorWithAlphaComponent(0.5)
        $0.borderWidth = 1
        $0.userInteractionEnabled = false
    }
    
    func showZoomLabel() {
        self.zoomLabel.text = "\(Int(zoomScale))"
        zoomLabel.setAlpha(1.0, animated: true)
        enqueueSelector(#selector(CameraViewController.hideZoomLabel), delay: 1.0)
    }
    
    func hideZoomLabel() {
        zoomLabel.setAlpha(0.0, animated: true)
    }
    
    deinit {
        VolumeChangeObserver.sharedObserver.unregister()
        DeviceManager.defaultManager.endUsingAccelerometer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DeviceManager.defaultManager.addReceiver(self)
        DeviceManager.defaultManager.beginUsingAccelerometer()
        
        AVCaptureDevice.authorize({ _ in
            if self.isAvatar {
                self.position = .Front
                self.flashMode = .Off
            } else {
                self.position = NSUserDefaults.standardUserDefaults().captureMediaDevicePosition
                self.flashMode = NSUserDefaults.standardUserDefaults().captureMediaFlashMode
            }
            self.flashModeControl.mode = self.flashMode
            self.cameraView.layer.session = self.session
            self.session.start()
            }) { _ in
                self.unauthorizedStatusView.hidden = false
                self.takePhotoButton.active = false
        }
        
        assetsViewController.delegate = delegate
        assetsViewController.isAvatar = isAvatar
        addContainedViewController(assetsViewController, toView: assetsContentView, animated: false)
        
        UIAlertController.showNoMediaAccess(!isAvatar)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        enqueueSelector(#selector(CameraViewController.hideAssets), delay: 3.0)
        self.assetsViewController.assetsHidingHandler = { [weak self] _ in
            if let controller = self {
                NSObject.cancelPreviousPerformRequestsWithTarget(controller, selector: #selector(CameraViewController.hideAssets), object: nil)
            }
        }
        registerOnVolumeChange()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        VolumeChangeObserver.sharedObserver.unregister()
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(CameraViewController.hideAssets), object: nil)
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
        delegate?.cameraViewController?(self, didCaptureImage: image, saveToAlbum: true)
    }
    
    private func captureImage(completon: Block?) {
        delegate?.cameraViewControllerWillCaptureImage?(self)
        setAssetsViewControllerHidden(true, animated: true)
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
        return delegate?.cameraViewControllerCanCaptureMedia?(self) ?? true
    }
    
    func hideAssets() {
        setAssetsViewControllerHidden(true, animated: true)
    }
    
    func setAssetsViewControllerHidden(hidden: Bool, animated: Bool) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:#selector(CameraViewController.hideAssets), object:nil)
        self.assetsHeightConstraint.constant = hidden ? -self.assetsViewController.view.height : 0
        UIView.animateWithDuration(animated ? 0.3 : 0) {
            if (hidden) {
                self.assetsArrow.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI), 1, 0, 0)
            } else {
                self.assetsArrow.layer.transform = CATransform3DIdentity
            }
            self.view.layoutIfNeeded()
        }
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
        flashModeControl.setSelecting(false, animated: true)
        func orientationTransform(orientation: UIDeviceOrientation) -> CGAffineTransform {
            switch orientation {
            case .LandscapeLeft: return CGAffineTransformMakeRotation(CGFloat(M_PI_2))
            case .LandscapeRight: return CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
            case .PortraitUpsideDown: return CGAffineTransformMakeRotation(CGFloat(M_PI))
            default: return CGAffineTransformIdentity
            }
        }
        let transform = orientationTransform(orientation)
        UIView.animateWithDuration(0.25) { self.animateOrientationChange(transform) }
    }
    
    internal func animateOrientationChange(transform: CGAffineTransform) {
        backButton.transform = transform
        rotateButton.transform = transform
        takePhotoButton.transform = transform
        for subView in flashModeControl.subviews {
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
        delegate?.cameraViewControllerDidCancel?(self)
    }
    
    @IBAction func shot(sender: AnyObject?) {
        if canCaptureMedia() {
            captureImage(nil)
        }
    }
    
    @IBAction func panning(sender: UIPanGestureRecognizer) {
        let minHeight = -assetsViewController.view.height
        let constraint = self.assetsHeightConstraint
        if (sender.state == .Changed) {
            let translation = sender.translationInView(sender.view)
            constraint.constant = smoothstep(minHeight, 0, constraint.constant - translation.y / 2)
            assetsArrow.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI) * constraint.constant / minHeight, 1, 0, 0)
            view.layoutIfNeeded()
            sender.setTranslation(CGPointZero, inView: sender.view)
        } else if (sender.state == .Ended || sender.state == .Cancelled) {
            let velocity = sender.velocityInView(sender.view).y
            if abs(velocity) > 500 {
                setAssetsViewControllerHidden(velocity > 0, animated: true)
            } else {
                setAssetsViewControllerHidden(constraint.constant < minHeight/2, animated: true)
            }
        }
    }
    
    @IBAction func toggleQuickAssets(sender: AnyObject?) {
        setAssetsViewControllerHidden(assetsHeightConstraint.constant == 0, animated: true)
    }
    
    @IBAction func getSamplePhoto(sender: AnyObject?) {
        self.takePhotoButton.active = false
        fetchSampleImage({ (image) -> Void in
            self.delegate?.cameraViewController?(self, didCaptureImage:image, saveToAlbum:false)
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
        if sender.state == .Changed {
            let device = self.videoInput?.device
            zoomScale = smoothstep(1, min(8, device?.activeFormat?.videoMaxZoomFactor ?? 1), zoomScale * sender.scale)
            sender.scale = 1
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
    
//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
}

extension CameraViewController: DeviceManagerNotifying {
    func manager(manager: DeviceManager, didChangeOrientation orientation: UIDeviceOrientation) {
        applyDeviceOrientation(orientation)
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
