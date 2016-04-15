//
//  CaptureAvatarViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/16/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import Photos

@objc protocol CaptureAvatarViewControllerDelegate {
    func captureViewController(controller: CaptureAvatarViewController, didFinishWithAvatar avatar: MutableAsset)
    func captureViewControllerDidCancel(controller: CaptureAvatarViewController)
}

class CaptureAvatarViewController: CaptureViewController {
    
    weak var captureDelegate: CaptureAvatarViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraViewController?.isAvatar = true
    }
    
    override func resizeImageWidth() -> CGFloat {
        return 600
    }
    
    private func finish(avatar: MutableAsset) {
        captureDelegate?.captureViewController(self, didFinishWithAvatar: avatar)
    }
    
    private func handleImage(image: UIImage, saveToAlbum: Bool) {
        editImage(image) { [weak self] (image) -> Void in
            let asset = MutableAsset(isAvatar: true)
            asset.setImage(image)
            if saveToAlbum {
                asset.saveToAssets()
            }
            self?.finish(asset)
        }
    }
    
    private func editImage(image: UIImage, completionHandler: UIImage -> Void) {
        if let controller = storyboard?["editAvatar"] as? EditAvatarViewController {
            controller.image = image;
            controller.completionHandler = completionHandler
            pushViewController(controller, animated: false)
        }
    }
    
    func handleAsset(asset: PHAsset) {
        view.userInteractionEnabled = false
        cropAsset(asset, completion: { [weak self] (croppedImage) -> Void in
            if let image = croppedImage {
                self?.handleImage(image, saveToAlbum: false)
            }
            self?.view.userInteractionEnabled = true
        })
    }
}

extension CaptureAvatarViewController {
    
    func assetsViewController(controller: AssetsViewController, shouldSelectAsset asset: PHAsset) -> Bool {
        handleAsset(asset)
        return false
    }
    
    func cameraViewController(controller: CameraViewController, didCaptureImage image: UIImage, saveToAlbum: Bool) {
        view.userInteractionEnabled = false
        cropImage(image) { [weak self] (image) -> Void in
            self?.handleImage(image, saveToAlbum: saveToAlbum)
            self?.view.userInteractionEnabled = true
        }
    }
    
    func cameraViewControllerDidCancel(controller: CameraViewController) {
        if let delegate = captureDelegate {
            delegate.captureViewControllerDidCancel(self)
        } else {
            presentingViewController?.dismissViewControllerAnimated(false, completion:nil)
        }
    }
}

class EditAvatarViewController: BaseViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    
    var image: UIImage?
    
    var completionHandler: (UIImage -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        UIView.performWithoutAnimation { UIViewController.attemptRotationToDeviceOrientation() }
    }
    
    override func requestAuthorizationForPresentingEntry(entry: Entry, completion: BooleanBlock) {
        UIAlertController.alert("unsaved_photo".ls, message: "leave_screen_on_editing".ls).action("cancel".ls, handler: { _ in
            completion(false)
        }).action("discard_changes".ls, handler: { _ in completion(true) }).show()
    }
    
    @IBAction func edit(sender: AnyObject) {
        guard let image = image else { return }
        let controller = ImageEditor.editControllerWithImage(image, completion: { [weak self] (image) -> Void in
            self?.image = image
            self?.imageView.image = image
            self?.navigationController?.popViewControllerAnimated(false)
            }) { [weak self] _ in
                self?.navigationController?.popViewControllerAnimated(false)
        }
        navigationController?.pushViewController(controller, animated:false)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(false)
    }
    
    @IBAction func done(sender: AnyObject) {
        view.endEditing(true)
        if let image = image {
            completionHandler?(image)
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .All
    }
}