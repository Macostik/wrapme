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
    
    class func captureMediaViewController(wrap: Wrap?) -> CaptureMediaViewController {
        let controller = UIStoryboard.camera()["captureMedia"] as! CaptureMediaViewController
        controller.wrap = wrap
        return controller
    }
    
    class func captureAvatarViewController() -> CaptureAvatarViewController {
        return UIStoryboard.camera()["captureAvatar"] as! CaptureAvatarViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cameraViewController = viewControllers.last as? CameraViewController
        cameraViewController?.delegate = self
        self.cameraViewController = cameraViewController
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    override func requestAuthorizationForPresentingEntry(entry: Entry, completion: BooleanBlock) {
        topViewController?.requestAuthorizationForPresentingEntry(entry, completion: completion)
    }
    
    func resizeImageWidth() -> CGFloat {
        return 1200
    }
        
    internal func cropImage(image: UIImage, completion: UIImage -> Void) {
        Dispatch.defaultQueue.async { [weak self] _ in
            let resultImage = self?.cropImage(image) ?? image
            Dispatch.mainQueue.async { completion(resultImage) }
        }
    }
    
    internal func cropImage(image: UIImage) -> UIImage {
        var resultImage = resizeImage(image)
        let cropRect = CGRectThatFitsSize(resultImage.size, view.size);
        resultImage = resultImage.crop(cropRect)
        return resultImage
    }
    
    internal func resizeImage(image: UIImage) -> UIImage {
        let resultWidth = resizeImageWidth()
        let fitSize = CGSizeThatFitsSize(image.size, view.size);
        if (image.size.width > image.size.height) {
            let scale = image.size.height / fitSize.height
            return image.resize(CGSizeMake(1, resultWidth * scale), aspectFill:true)
        } else {
            let scale = image.size.width / fitSize.width
            return image.resize(CGSizeMake(resultWidth * scale, 1), aspectFill:true)
        }
    }
    
    internal func cropAsset(asset: PHAsset, options: PHImageRequestOptions, completion: UIImage? -> Void) {
        let width = CGFloat(asset.pixelWidth)
        let height = CGFloat(asset.pixelHeight)
        let scale = (width > height ? height : width) / resizeImageWidth()
        let size = scale < 0.5 && UIDevice.currentDevice().systemVersionBefore("9") ?
        CGSizeMake(width * scale, height * scale) : CGSizeMake(width / scale, height / scale);
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: size, contentMode: .AspectFill, options: options) { (image, _) -> Void in
            completion(image)
        }
    }
}
