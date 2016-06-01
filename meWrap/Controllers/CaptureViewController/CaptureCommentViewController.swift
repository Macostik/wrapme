//
//  CaptureCommentViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 5/11/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import Photos

protocol CaptureCommentViewControllerDelegate: class {
    func captureViewController(controller: CaptureCommentViewController, didFinishWithAsset asset: MutableAsset)
    func captureViewControllerDidCancel(controller: CaptureCommentViewController)
}

final class CaptureCommentViewController: CaptureViewController {
    
    weak var captureDelegate: CaptureCommentViewControllerDelegate?
    
    private var asset: MutableAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let cameraViewController = cameraViewController {
            performWhenLoaded(cameraViewController) {
                $0.assetsViewController.cancelAutoHide()
                $0.assetsViewController.setHidden(true, animated: false)
            }
        }
    }
    
    private func handleImage(image: UIImage, saveToAlbum: Bool) {
        let asset = MutableAsset(isAvatar: false)
        asset.canBeSavedToAssets = saveToAlbum
        prepareAndUploadAsset(asset) { (completion) in
            asset.setImage(image, completion: { [weak self] _ in
                self?.cameraViewController?.handleImageSetup?()
                completion()
                })
        }
        self.asset = asset
    }
    
    private func handleAsset(asset: PHAsset) {
        let mediaAsset = MutableAsset(isAvatar: false)
        mediaAsset.assetID = asset.localIdentifier
        mediaAsset.date = asset.creationDate ?? NSDate.now()
        mediaAsset.type = asset.mediaType == .Video ? .Video : .Photo
        prepareAndUploadAsset(mediaAsset) { (completion) in
            if (asset.mediaType == .Video) {
                mediaAsset.setVideoFromAsset(asset, completion: completion)
            } else {
                cropAsset(asset, completion: { (croppedImage) -> Void in
                    if let image = croppedImage {
                        let isDowngrading = PHPhotoLibrary.containApplicationAlbumAsset(asset) ?? false
                        mediaAsset.setImage(image, isDowngrading: !isDowngrading, completion: completion)
                    }
                    })
            }
        }
        self.asset = mediaAsset
    }
    
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
    
    func cancel() {
        if let delegate = captureDelegate {
            delegate.captureViewControllerDidCancel(self)
        } else {
            presentingViewController?.dismissViewControllerAnimated(false, completion:nil)
        }
    }
    
    func cameraViewControllerDidCancel(controller: CameraViewController) {
        cancel()
    }
    
    func cameraViewController(controller: CameraViewController, didCaptureVideoAtPath path: String, saveToAlbum: Bool) {
        let asset = MutableAsset(isAvatar: false)
        asset.type = .Video
        asset.date = NSDate.now()
        asset.canBeSavedToAssets = saveToAlbum
        self.asset = asset
        prepareAndUploadAsset(asset) { (completion) in
            asset.setVideoFromRecordAtPath(path, completion: completion)
        }
    }
    
    weak var uploadMediaCommentViewController: UploadMediaCommentViewController?
    
    func prepareAndUploadAsset(asset: MutableAsset, @noescape prepare: (() -> ()) -> ()) {
        let controller = UploadMediaCommentViewController()
        prepare({
            controller.setAsset(asset)
        })
        controller.uploadButton.addTarget(self, touchUpInside: #selector(self.upload))
        controller.closeButton.addTarget(self, touchUpInside: #selector(self.cancel))
        self.pushViewController(controller, animated: false)
        uploadMediaCommentViewController = controller
    }
    
    @objc private func upload() {
        if let asset = asset {
            asset.comment = uploadMediaCommentViewController?.composeBar.text?.trim
            asset.saveToAssetsIfNeeded()
            captureDelegate?.captureViewController(self, didFinishWithAsset: asset)
        }
    }
}

final class UploadMediaCommentViewController: UIViewController, ComposeBarDelegate {
    
    let uploadButton = Button(icon: "g", size: 24, textColor: UIColor.whiteColor())
    let closeButton = Button(type: .Custom)
    
    var videoPlayer: VideoPlayer?
    
    var imageView: ImageView?
    
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
    
    let composeBar = ComposeBar()
    
    override func loadView() {
        super.loadView()
        
        let gradientView = GradientView()
        gradientView.startColor = UIColor.blackColor()
        gradientView.contentMode = .Top
        view.add(gradientView) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        closeButton.titleLabel?.font = Font.Small + .Regular
        closeButton.setTitleColor(Color.orange, forState: .Normal)
        closeButton.setTitle("close".ls, forState: .Normal)
        gradientView.add(closeButton) { (make) in
            make.centerY.equalTo(gradientView.snp_top).inset(22)
            make.trailing.equalTo(gradientView).inset(12)
        }
        uploadButton.cornerRadius = 36
        uploadButton.normalColor = Color.green.colorWithAlphaComponent(0.9)
        uploadButton.backgroundColor = uploadButton.normalColor
        uploadButton.highlightedColor = Color.green.darkerColor().colorWithAlphaComponent(0.9)
        view.add(uploadButton) { (make) in
            make.bottom.equalTo(view).inset(12)
            make.centerX.equalTo(view)
            make.size.equalTo(72)
        }
        let deleteButton = Button.expandableCandyAction("n")
        deleteButton.backgroundColor = UIColor(white: 0, alpha: 0.8)
        deleteButton.addTarget(self, touchUpInside: #selector(self.retake))
        view.add(deleteButton) { (make) in
            make.trailing.equalTo(view).inset(12)
            make.centerY.equalTo(uploadButton)
            make.size.equalTo(44)
        }
        spinner.hidesWhenStopped = true
        view.add(spinner) { (make) in
            make.center.equalTo(view)
        }
        spinner.startAnimating()
        uploadButton.userInteractionEnabled = false
        
        composeBar.backgroundColor = UIColor(white: 0, alpha: 0.7)
        composeBar.delegate = self
        composeBar.textView.placeholder = "add_caption".ls
        composeBar.emojiButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        composeBar.doneButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        composeBar.doneButton.setTitle("E", forState: .Normal)
        view.add(composeBar) { (make) in
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(uploadButton.snp_top).inset(-12)
        }
    }
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        composeBar.resignFirstResponder()
        composeBar.setDoneButtonHidden(true, animated: true)
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        let comment = composeBar.text ?? ""
        if comment.characters.count > Constants.wrapNameLimit {
            composeBar.text = comment.substringToIndex(comment.startIndex.advancedBy(Constants.wrapNameLimit))
        }
    }
    
    override func requestPresentingPermission(completion: BooleanBlock) {
        UIAlertController.alert("unsaved_media".ls, message: "leave_screen_on_editing".ls).action("cancel".ls, handler: { _ in
            completion(false)
        }).action("discard_changes".ls, handler: { _ in completion(true) }).show()
    }
    
    func setAsset(asset: MutableAsset) {
        uploadButton.userInteractionEnabled = true
        spinner.stopAnimating()
        if asset.type == .Video {
            let videoPlayer = VideoPlayer()
            view.insertSubview(videoPlayer, atIndex: 0)
            videoPlayer.snp_makeConstraints { (make) in
                make.edges.equalTo(view)
            }
            videoPlayer.url = asset.original?.fileURL
            videoPlayer.playing = true
            videoPlayer.muted = false
            self.videoPlayer = videoPlayer
            (videoPlayer.layer as? AVPlayerLayer)?.videoGravity = AVLayerVideoGravityResizeAspectFill
            view.add(videoPlayer.volumeButton) { (make) in
                make.leading.equalTo(view).inset(12)
                make.centerY.equalTo(uploadButton)
                make.size.equalTo(44)
            }
        } else {
            let imageView = ImageView(backgroundColor: UIColor.clearColor())
            view.insertSubview(imageView, atIndex: 0)
            imageView.snp_makeConstraints { (make) in
                make.edges.equalTo(view)
            }
            imageView.url = asset.original
            self.imageView = imageView
        }
    }
    
    @objc private func retake() {
        self.navigationController?.popViewControllerAnimated(false)
    }
}
