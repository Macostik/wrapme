//
//  CaptureViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import Photos

class CaptureViewController: UINavigationController, CameraViewControllerDelegate {
    
    weak var cameraViewController: CameraViewController?
    
    var friendsInvited = false
    
    static func captureMediaViewController(wrap: Wrap?) -> CaptureCandyViewController {
        let controller = CaptureCandyViewController(cameraViewController: CandyCameraViewController())
        controller.wrap = wrap
        return controller
    }
    
    static func captureAvatarViewController() -> CaptureAvatarViewController {
        let cameraViewController = AvatarCameraViewController()
        return CaptureAvatarViewController(cameraViewController: cameraViewController, defaultPosition: .Front)
    }
    
    static func captureCommentViewController() -> CaptureCommentViewController {
        let cameraViewController = CommentCameraViewController()
        return CaptureCommentViewController(cameraViewController: cameraViewController, defaultPosition: .Front)
    }
    
    convenience init(cameraViewController: CameraViewController, defaultPosition: AVCaptureDevicePosition = NSUserDefaults.standardUserDefaults().captureMediaDevicePosition) {
        self.init()
        cameraViewController.defaultPosition = defaultPosition
        navigationBarHidden = true
        self.cameraViewController = cameraViewController
        cameraViewController.delegate = self
        viewControllers = [cameraViewController]
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    override func requestPresentingPermission(completion: BooleanBlock) {
        topViewController?.requestPresentingPermission(completion)
    }
    
    func resizeImageWidth() -> CGFloat {
        return 1080
    }
        
    internal func cropImage(image: UIImage, completion: UIImage -> Void) {
        Dispatch.defaultQueue.async { [weak self] _ in
            let resultImage = self?.cropImage(image) ?? image
            Dispatch.mainQueue.async { completion(resultImage) }
        }
    }
    
    internal func cropImage(image: UIImage) -> UIImage {
        let resultImage = resizeImage(image)
        let cropRect = resultImage.size.fit(viewFinderSize()).rectCenteredInSize(resultImage.size)
        return resultImage.crop(cropRect)
    }
    
    private func viewFinderSize() -> CGSize {
        if DeviceManager.defaultManager.orientation.isLandscape {
            return CGSize(width: view.height, height: view.width)
        } else {
            return view.size
        }
    }
    
    internal func resizeImage(image: UIImage) -> UIImage {
        let resultWidth = resizeImageWidth()
        let fitSize = image.size.fit(viewFinderSize())
        if image.size.width > image.size.height {
            let scale = image.size.height / fitSize.height
            return image.resize(CGSizeMake(1, resultWidth * scale), aspectFill:true)
        } else {
            let scale = image.size.width / fitSize.width
            return image.resize(CGSizeMake(resultWidth * scale, 1), aspectFill:true)
        }
    }
    
    internal func cropAsset(asset: PHAsset, completion: UIImage? -> Void) {
        let width = CGFloat(asset.pixelWidth)
        let height = CGFloat(asset.pixelHeight)
        let scale = (width > height ? height : width) / resizeImageWidth()
        let size = CGSizeMake(width / scale, height / scale)
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true
        PHImageManager.defaultManager().requestImageDataForAsset(asset, options: options) { (data, _, _, info) in
            if let data = data, let image = UIImage(data: data) {
                completion(image.resize(size))
            } else {
                completion(nil)
            }
        }
    }
    
    func assetsViewController(controller: AssetsViewController, shouldSelectAsset asset: PHAsset) -> Bool { return true }
    func assetsViewController(controller: AssetsViewController, didSelectAsset asset: PHAsset) {}
    func assetsViewController(controller: AssetsViewController, didDeselectAsset asset: PHAsset) {}
    func cameraViewController(controller: CameraViewController, didCaptureImage image: UIImage, saveToAlbum: Bool) {}
    func cameraViewControllerDidCancel(controller: CameraViewController) {}
    func cameraViewControllerDidFailImageCapturing(controller: CameraViewController) {}
    func cameraViewControllerWillCaptureImage(controller: CameraViewController) {}
    func cameraViewController(controller: CameraViewController, didCaptureVideoAtPath path: String, saveToAlbum: Bool) {}
    func cameraViewControllerDidFinish(controller: CameraViewController) {}
    func cameraViewControllerCanCaptureMedia(controller: CameraViewController) -> Bool { return true }
}
