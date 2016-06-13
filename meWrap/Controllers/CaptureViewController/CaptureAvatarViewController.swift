//
//  CaptureAvatarViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/16/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import Photos

protocol CaptureAvatarViewControllerDelegate: class {
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
        let controller = EditAvatarViewController()
        controller.image = image
        controller.completionHandler = completionHandler
        pushViewController(controller, animated: false)
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
    
    override func assetsViewController(controller: AssetsViewController, shouldSelectAsset asset: PHAsset) -> Bool {
        handleAsset(asset)
        return false
    }
    
    override func cameraViewController(controller: CameraViewController, didCaptureImage image: UIImage, saveToAlbum: Bool) {
        view.userInteractionEnabled = false
        cropImage(image) { [weak self] (image) -> Void in
            self?.handleImage(image, saveToAlbum: saveToAlbum)
            self?.view.userInteractionEnabled = true
        }
    }
    
    override func cameraViewControllerDidCancel(controller: CameraViewController) {
        if let delegate = captureDelegate {
            delegate.captureViewControllerDidCancel(self)
        } else {
            presentingViewController?.dismissViewControllerAnimated(false, completion:nil)
        }
    }
}

class AvatarCameraViewController: CameraViewController {
    
    override func loadView() {
        super.loadView()
        
        takePhotoButton.snp_makeConstraints { (make) in
            make.size.equalTo(72)
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).inset(12)
        }
        photoTakingView.add(backButton) { (make) in
            make.centerY.equalTo(takePhotoButton)
            make.leading.equalTo(photoTakingView).inset(12)
        }
        
        addCropAreaView()
    }
}

class EditAvatarViewController: BaseViewController {
    
    private let imageView = UIImageView()
    private let editButton = Button.candyAction("R", color: Color.blue, size: 24)
    private let doneButton = Button(icon: "E", size: 30, textColor: UIColor.whiteColor())
    private let cancelButton = Button(icon: "!", size: 24, textColor: UIColor.whiteColor())
    
    var image: UIImage?
    
    var completionHandler: (UIImage -> Void)?
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.blackColor()
        imageView.contentMode = .ScaleAspectFit
        
        let bottomView = view.add(UIView()) { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.height.equalTo(142)
        }
        
        view.add(imageView) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.bottom.equalTo(bottomView.snp_top)
        }
        
        editButton.cornerRadius = 22
        editButton.addTarget(self, touchUpInside: #selector(self.edit(_:)))
        
        doneButton.highlightedColor = Color.grayLight
        doneButton.cornerRadius = 30
        doneButton.setBorder(width: 2)
        doneButton.addTarget(self, touchUpInside: #selector(self.done(_:)))
        
        cancelButton.highlightedColor = Color.grayLight
        cancelButton.cornerRadius = 30
        cancelButton.setBorder(width: 2)
        cancelButton.addTarget(self, touchUpInside: #selector(self.cancel(_:)))
        
        view.add(editButton) { (make) in
            make.trailing.bottom.equalTo(imageView).inset(12)
            make.size.equalTo(44)
        }
        
        bottomView.add(doneButton) { (make) in
            make.centerY.equalTo(bottomView)
            make.centerX.equalTo(bottomView).inset(78)
            make.size.equalTo(60)
        }
        
        bottomView.add(cancelButton) { (make) in
            make.centerY.equalTo(bottomView)
            make.centerX.equalTo(bottomView).inset(-78)
            make.size.equalTo(60)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        UIView.performWithoutAnimation { UIViewController.attemptRotationToDeviceOrientation() }
    }
    
    override func requestPresentingPermission(completion: BooleanBlock) {
        UIAlertController.alert("unsaved_media".ls, message: "leave_screen_on_editing".ls).action("cancel".ls, handler: { _ in
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