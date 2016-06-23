//
//  CaptureCandyViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/17/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import Photos

protocol CaptureWrapContainer: class {
    weak var wrap: Wrap? { get set }
    var wrapView: WrapView { get }
    func setupWrapView(wrap: Wrap?)
}

extension CaptureWrapContainer {
    func setupWrapView(wrap: Wrap?) {
        wrapView.wrap = wrap
        wrapView.hidden = wrap == nil
    }
}

protocol CaptureCandyViewControllerDelegate: class {
    func captureViewController(controller: CaptureCandyViewController, didFinishWithAssets assets: [MutableAsset])
    func captureViewControllerDidCancel(controller: CaptureCandyViewController)
}

class CaptureCandyViewController: CaptureViewController, UploadSummaryViewControllerDelegate, WrapPickerViewControllerDelegate {
        
    weak var captureDelegate: CaptureCandyViewControllerDelegate?
    
    private var runQueue = RunQueue(limit: 1)
    
    private var assets = [MutableAsset]()
    
    private var assetsCount = 0
    
    private weak var assetsViewController: AssetsViewController?
    
    lazy var createdWraps: Set<Wrap> = Set<Wrap>()
    
    weak var wrap: Wrap? {
        didSet {
            for controller in viewControllers {
                if let container = controller as? CaptureWrapContainer {
                    container.wrap = wrap
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let cameraViewController = cameraViewController as? CandyCameraViewController {
            cameraViewController.wrap = wrap
            cameraViewController.changeWrap = { [weak self] _ in
                self?.showWrapPicker()
            }
        }
        
        Dispatch.mainQueue.async { self.updateCountLabel() }
        Wrap.notifier().addReceiver(self)
        if wrap == nil {
            showWrapPicker()
        }
    }
    
    func showWrapPicker() {
        view.layoutIfNeeded()
        let controller = WrapPickerViewController()
        controller.delegate = self
        controller.wrap = wrap
        controller.showInViewController(self)
    }
    
    override func toastAppearanceViewController(toast: UIView?) -> UIViewController {
        for controller in self.childViewControllers where controller is WrapPickerViewController {
            return controller
        }
        return topViewController?.toastAppearanceViewController(toast) ?? self
    }
    
    private func handleImage(image: UIImage, saveToAlbum: Bool) {
        let asset = MutableAsset(isAvatar: false)
        asset.canBeSavedToAssets = saveToAlbum
        addAsset(asset, success: { (_) -> Void in
            runQueue.run { (finish) -> Void in
                asset.setImage(image, completion: {
                    finish()
                    self.cameraViewController?.handleImageSetup?()
                })
            }
            }) { $0?.show() }
    }
    
    private func handleAsset(asset: PHAsset) {
        let mediaAsset = MutableAsset(isAvatar: false)
        mediaAsset.assetID = asset.localIdentifier
        mediaAsset.date = asset.creationDate ?? NSDate.now()
        mediaAsset.type = asset.mediaType == .Video ? .Video : .Photo
        addAsset(mediaAsset, success: { (_) -> Void in
            runQueue.run { [weak self] (finish) -> Void in
                if (asset.mediaType == .Video) {
                    mediaAsset.setVideoFromAsset(asset, completion: finish)
                } else {
                    self?.cropAsset(asset, completion: { (croppedImage) -> Void in
                        if let image = croppedImage {
                            let isDowngrading = PHPhotoLibrary.containApplicationAlbumAsset(asset) ?? false
                            mediaAsset.setImage(image, isDowngrading: !isDowngrading, completion: finish)
                        } else {
                            finish()
                        }
                    })
                }
            }
            }) { $0?.show() }
    }
    
    private func handleAssets(assets: [PHAsset]) {
        for asset in assets {
            handleAsset(asset)
        }
    }
    
    private func addAsset(asset: MutableAsset, @noescape success: ObjectBlock, @noescape failure: FailureBlock) {
        shouldAddAsset({ () -> Void in
            assets.append(asset)
            assetsCount = assets.count
            updateCountLabel()
            success(asset)
            if assets.count == 10 {
                showUploadSummary {
                    Toast.show("upload_photos_limit_error".ls)
                }
            }
            }, failure: failure)
    }
    
    private func shouldAddAsset( @noescape success: Block, @noescape failure: FailureBlock) -> Bool {
        if assets.count < 10 {
            success()
            return true
        } else {
            failure(NSError(message:"upload_photos_limit_error".ls))
            return false
        }
    }

    private func updateCountLabel() {
        if assetsCount < 0 {
            assetsCount = 0
        }
        cameraViewController?.takePhotoButton.setTitle("\(assetsCount)", forState: .Normal)
        (cameraViewController as? CandyCameraViewController)?.finishButton.hidden = assetsCount == 0
    }
    
    private func showUploadSummary(completionHandler: (Void -> Void)?) {
        let queue = runQueue
        
        let completionBlock: Block = { [weak self] _ in
            queue.didFinish = nil
            let controller = UploadSummaryViewController()
            controller.assets = self?.assets.sort({ $0.date < $1.date }) ?? []
            controller.delegate = self
            controller.changeWrap = { self?.showWrapPicker() }
            controller.wrap = self?.wrap
            self?.pushViewController(controller, animated: false)
            completionHandler?()
        }
        
        if queue.isExecuting {
            weak var finishButton = (cameraViewController as? CandyCameraViewController)?.finishButton
            finishButton?.loading = true
            queue.didFinish = {
                finishButton?.loading = false
                completionBlock()
            }
        } else {
            completionBlock()
        }
    }
    
    override func assetsViewController(controller: AssetsViewController, shouldSelectAsset asset: PHAsset) -> Bool {
        if asset.mediaType == .Video && asset.duration >= Constants.maxVideoRecordedDuration + 1 {
            Toast.show(String(format:"formatted_upload_video_duration_limit".ls, Int(Constants.maxVideoRecordedDuration)))
            return false
        } else {
            return shouldAddAsset({}, failure: { $0?.show() })
        }
    }
    
    override func assetsViewController(controller: AssetsViewController, didSelectAsset asset: PHAsset) {
        assetsViewController = controller
        handleAsset(asset)
    }
    
    override func assetsViewController(controller: AssetsViewController, didDeselectAsset asset: PHAsset) {
        for (index, _asset) in self.assets.enumerate() where _asset.assetID == asset.localIdentifier {
            if let exportSession = _asset.videoExportSession {
                exportSession.cancelExport()
            }
            assets.removeAtIndex(index)
            assetsCount = assets.count
            break
        }
        updateCountLabel()
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
    
    override func cameraViewControllerWillCaptureImage(controller: CameraViewController) {
        assetsCount += 1
        updateCountLabel()
    }
    
    override func cameraViewControllerDidFailImageCapturing(controller: CameraViewController) {
        assetsCount -= 1
        updateCountLabel()
    }
    
    override func cameraViewControllerDidFinish(controller: CameraViewController) {
        showUploadSummary(nil)
    }
    
    override func cameraViewControllerCanCaptureMedia(controller: CameraViewController) -> Bool {
        return shouldAddAsset({}, failure: { $0?.show() })
    }
    
    override func cameraViewController(controller: CameraViewController, didCaptureVideoAtPath path: String, saveToAlbum: Bool) {
        let asset = MutableAsset(isAvatar: false)
        asset.type = .Video
        asset.date = NSDate.now()
        asset.canBeSavedToAssets = saveToAlbum
        addAsset(asset, success: { (_) -> Void in
            controller.takePhotoButton.userInteractionEnabled = false
            runQueue.run { (finish) -> Void in
                asset.setVideoFromRecordAtPath(path, completion: {
                    finish()
                    controller.takePhotoButton.userInteractionEnabled = true
                })
            }
        }) { $0?.show() }
    }
    
    func uploadSummaryViewController(controller: UploadSummaryViewController, didDeselectAsset asset: MutableAsset) {
        if let index = assets.indexOf(asset) {
            assets.removeAtIndex(index)
            assetsCount = assets.count
        }
        
        if let assetID = asset.assetID {
            assetsViewController?.selectedAssets.remove(assetID)
            assetsViewController?.streamView.reload()
        }
        
        updateCountLabel()
    }
    
    private func finish(assets: [MutableAsset]) {
        let delegate = captureDelegate ?? UINavigationController.main.viewControllers.first as? CaptureCandyViewControllerDelegate
        delegate?.captureViewController(self, didFinishWithAssets: assets)
    }
    
    func uploadSummaryViewController(controller: UploadSummaryViewController, didFinishWithAssets assets: [MutableAsset]) {
        for asset in assets {
            asset.saveToAssetsIfNeeded()
        }
        if let wrap = self.wrap where createdWraps.contains(wrap) {
            let controller = AddContributorsViewController(wrap: wrap)
            controller.isWrapCreation = true
            controller.completionHandler = { [weak self] friendsInvited in
                self?.friendsInvited = friendsInvited
                self?.finish(assets)
            }
            pushViewController(controller, animated: false)
        } else {
            finish(assets)
        }
    }
    
    func wrapPickerViewController(controller: WrapPickerViewController, didCreateWrap wrap: Wrap) {
        createdWraps.insert(wrap)
    }
    
    func wrapPickerViewController(controller: WrapPickerViewController, didSelectWrap wrap: Wrap) {
        self.wrap = wrap
    }
    
    func wrapPickerViewControllerDidCancel(controller: WrapPickerViewController) {
        if wrap != nil {
            controller.hide()
        } else {
            captureDelegate?.captureViewControllerDidCancel(self)
        }
    }
    
    func wrapPickerViewControllerDidFinish(controller: WrapPickerViewController) {
        controller.hide()
    }
}

extension CaptureCandyViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        if let wrap = self.wrap where createdWraps.contains(wrap) {
            createdWraps.remove(wrap)
        }
        wrap = User.currentUser?.sortedWraps.first
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
}
