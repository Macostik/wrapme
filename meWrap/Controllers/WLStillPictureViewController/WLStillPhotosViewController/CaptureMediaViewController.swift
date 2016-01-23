//
//  CaptureMediaViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/17/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import Photos

class CaptureMediaViewController: WLStillPictureViewController {
    
    private var runQueue = RunQueue(limit: 1)
    
    private var assets = [MutableAsset]()
    
    private var assetsCount = 0
    
    private weak var assetsViewController: AssetsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        Dispatch.mainQueue.async { self.updateCountLabel() }
    }
    
    override func handleImage(image: UIImage!, saveToAlbum: Bool) {
        let asset = MutableAsset()
        asset.isAvatar = isAvatar
        asset.canBeSavedToAssets = saveToAlbum
        addAsset(asset, success: { (_) -> Void in
            runQueue.run { (finish) -> Void in
                asset.setImage(image, completion: { (_) -> Void in
                    finish()
                })
            }
            }) { $0?.show() }
    }
    
    func handleAsset(asset: PHAsset) {
        let mediaAsset = MutableAsset()
        mediaAsset.isAvatar = self.isAvatar;
        mediaAsset.assetID = asset.localIdentifier
        mediaAsset.date = asset.creationDate ?? NSDate.now()
        mediaAsset.type = asset.mediaType == .Video ? .Video : .Photo
        addAsset(mediaAsset, success: { (_) -> Void in
            runQueue.run { [weak self] (finish) -> Void in
                if (asset.mediaType == .Video) {
                    mediaAsset.setVideoFromAsset(asset, completion: { (_) -> Void in
                        finish()
                    })
                } else {
                    let option = PHImageRequestOptions()
                    option.resizeMode = .Exact
                    option.deliveryMode = .HighQualityFormat
                    self?.cropAsset(asset, option:option, completion: { (croppedImage) -> Void in
                        mediaAsset.setImage(croppedImage, completion: { (_) -> Void in
                            finish()
                        })
                    })
                }
            }
            }) { $0?.show() }
    }
    
    func handleAssets(assets: [PHAsset]) {
        for asset in assets {
            handleAsset(asset)
        }
    }
    
    func addAsset(asset: MutableAsset, @noescape success: ObjectBlock, @noescape failure: FailureBlock) {
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
    
    func shouldAddAsset( @noescape success: Block, @noescape failure: FailureBlock) -> Bool {
        if assets.count < 10 {
            success()
            return true
        } else {
            failure(NSError(message:"upload_photos_limit_error".ls))
            return false
        }
    }

    func updateCountLabel() {
        if assetsCount < 0 {
            assetsCount = 0
        }
        cameraViewController?.takePhotoButton?.setTitle("\(assetsCount)", forState: .Normal)
        cameraViewController?.finishButton?.hidden = assetsCount == 0;
    }
    
    func assetsViewController(controller: AssetsViewController, shouldSelectAsset asset: PHAsset) -> Bool {
        if asset.mediaType == .Video && asset.duration >= Constants.maxVideoRecordedDuration + 1 {
            Toast.show(String(format:"formatted_upload_video_duration_limit".ls, Constants.maxVideoRecordedDuration))
            return false
        } else {
            return shouldAddAsset({}, failure: { $0?.show() })
        }
    }
    
    func assetsViewController(controller: AssetsViewController, didSelectAsset asset: PHAsset) {
        assetsViewController = controller
        handleAsset(asset)
    }
    
    func assetsViewController(controller: AssetsViewController, didDeselectAsset asset: PHAsset) {
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
    
    private func showUploadSummary(completionHandler: (Void -> Void)?) {
        let queue = runQueue
        
        let completionBlock: Block = { [weak self] _ in
            queue.didFinish = nil
            if let controller = self?.storyboard?["uploadSummary"] as? UploadSummaryViewController {
                controller.assets = self?.assets.sort { $0.date < $1.date }
                controller.delegate = self
                controller.wrap = self?.wrap
                self?.pushViewController(controller, animated: false)
                completionHandler?()
            }
        }
        
        if queue.isExecuting {
            cameraViewController?.finishButton?.loading = true
            queue.didFinish = { [weak self] _ in
                self?.cameraViewController?.finishButton?.loading = false
                completionBlock()
            }
        } else {
            completionBlock()
        }
        
    }
    
    override func cameraViewControllerWillCaptureImage(controller: WLCameraViewController!) {
        assetsCount++
        updateCountLabel()
    }
    
    override func cameraViewControllerDidFailImageCapturing(controller: WLCameraViewController!) {
        assetsCount--
        updateCountLabel()
    }
    
    override func cameraViewControllerDidFinish(controller: WLCameraViewController!) {
        showUploadSummary(nil)
    }
    
    override func cameraViewControllerCanCaptureMedia(controller: WLCameraViewController!) -> Bool {
        return shouldAddAsset({}, failure: { $0?.show() })
    }
    
    override func cameraViewController(controller: WLCameraViewController!, didCaptureVideoAtPath path: String!, saveToAlbum: Bool) {
        let asset = MutableAsset()
        asset.isAvatar = isAvatar
        asset.type = .Video
        asset.date = NSDate.now()
        asset.canBeSavedToAssets = saveToAlbum
        addAsset(asset, success: { (_) -> Void in
            controller.takePhotoButton?.userInteractionEnabled = false
            runQueue.run { (finish) -> Void in
                asset.setVideoFromRecordAtPath(path, completion: { (_) -> Void in
                    finish()
                    controller.takePhotoButton?.userInteractionEnabled = true
                })
            }
            }) { $0?.show() }
    }
}

extension CaptureMediaViewController: UploadSummaryViewControllerDelegate {
    
    func uploadSummaryViewController(controller: UploadSummaryViewController!, didDeselectAsset asset: MutableAsset!) {
        
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
    
    func uploadSummaryViewController(controller: UploadSummaryViewController!, didFinishWithAssets assets: [AnyObject]!) {
        for asset in assets as! [MutableAsset] {
            asset.saveToAssetsIfNeeded()
        }
        finishWithPictures(assets)
    }
}
