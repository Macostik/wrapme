//
//  CaptureAvatarViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/16/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import Photos

class CaptureAvatarViewController: WLStillPictureViewController {
    
    override func viewDidLoad() {
        isAvatar = true
        super.viewDidLoad()
    }
    
    override func handleImage(image: UIImage!, saveToAlbum: Bool) {
        editImage(image) { [unowned self] (image) -> Void in
            let asset = MutableAsset()
            asset.isAvatar = self.isAvatar
            asset.setImage(image)
            if saveToAlbum {
                asset.saveToAssets()
            }
            self.finishWithPictures([asset])
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
        let option = PHImageRequestOptions()
        option.resizeMode = .Exact
        option.deliveryMode = .HighQualityFormat
        cropAsset(asset, option:option, completion: { [weak self] (croppedImage) -> Void in
            self?.handleImage(croppedImage, saveToAlbum: false)
            self?.view.userInteractionEnabled = true
        })
    }
    
    func assetsViewController(controller: AssetsViewController, shouldSelectAsset asset: PHAsset) -> Bool {
        handleAsset(asset)
        return false
    }
}

class EditAvatarViewController: WLBaseViewController {
    
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
        }).action("continue".ls, handler: { _ in completion(true) })
    }
    
    @IBAction func edit(sender: AnyObject) {
        let controller = WLImageEditorSession.editControllerWithImage(image, completion: { [weak self] (image) -> Void in
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