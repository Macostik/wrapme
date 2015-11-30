//
//  MutableAsset.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/30/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class MutableAsset: Asset {
    var mode: WLStillPictureMode = .Default
    var comment: String?
    var canBeSavedToAssets: Bool = false
    var assetID: String?
    var date = NSDate.now()
    var edited = false
    var selected = false
    var deleted = false
    var uploaded = false
    weak var videoExportSession: AVAssetExportSession?
    
    deinit {
        if !uploaded {
            do {
                let manager = NSFileManager.defaultManager()
                if let original = original {
                    try manager.removeItemAtPath(original)
                }
                if let large = large where large != original {
                    try manager.removeItemAtPath(large)
                }
                if let medium = medium {
                    try manager.removeItemAtPath(medium)
                }
                if let small = small {
                    try manager.removeItemAtPath(small)
                }
                
            } catch {
            }
        }
    }
    
    func setImage(image: UIImage) {
        let cache = ImageCache.uploadingCache
        let isPad = UI_USER_INTERFACE_IDIOM() == .Pad
        let isCandy = mode == .Default
        let smallSize: CGFloat = isPad ? (isCandy ? 480 : 160) : (isCandy ? 240 : 160)
        let largePath = cache.getPath(cache.setImage(image))
        original = largePath
        large = largePath
        let thumbnail = image.thumbnail(smallSize)
        small = cache.getPath(cache.setImage(thumbnail))
    }
    
    func setImage(image: UIImage, completion: MutableAsset? -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] () -> Void in
            self?.setImage(image)
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                completion(self)
            })
        })
    }
    
    func setVideoAtPath(path: String) {
        original = path
        let asset = AVAsset(URL: NSURL(fileURLWithPath: path))
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let duration = CMTimeGetSeconds(asset.duration)
        let time = CMTimeMakeWithSeconds(duration/2.0, 600)
        let cache = ImageCache.defaultCache
        do {
            let quartzImage = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            let image = UIImage(CGImage: quartzImage)
            large = cache.getPath(cache.setImage(image))
            let thumbnail = image.thumbnail(240)
            small = cache.getPath(cache.setImage(thumbnail))
        } catch {
        }
    }
    
    func setVideoAtPath(path: String, completion: MutableAsset? -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] () -> Void in
            self?.setVideoAtPath(path)
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                completion(self)
                })
            })
    }
    
    func setVideoFromAsset(asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.version = .Original
        options.deliveryMode = .MediumQualityFormat
        options.networkAccessAllowed = true
        if let session = PHImageManager.defaultManager().requestExportSessionForVideo(asset, options: options, exportPreset: AVAssetExportPresetMediumQuality) {
            let outputPath = "\(NSHomeDirectory())/Documents/Videos/\(NSProcessInfo.processInfo().globallyUniqueString).mp4"
            session.outputURL = NSURL(fileURLWithPath: outputPath)
            session.outputFileType = AVFileTypeMPEG4
            session.shouldOptimizeForNetworkUse = true
            videoExportSession = session
            if session.export() {
                videoExportSession = nil
                setVideoAtPath(outputPath)
            }
        }
    }
    
    func setVideoFromAsset(asset: PHAsset, completion: MutableAsset? -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] () -> Void in
            self?.setVideoFromAsset(asset)
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                completion(self)
                })
            })
    }
    
    func setVideoFromRecordAtPath(path: String) {
        let asset = AVAsset(URL: NSURL(fileURLWithPath: path))
        if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) {
            let name = NSString.GUID()
            let outputPath = "\(NSHomeDirectory())/Documents/Videos/\(name).mp4"
            exportSession.outputURL = NSURL(fileURLWithPath: outputPath)
            exportSession.outputFileType = AVFileTypeMPEG4
            exportSession.shouldOptimizeForNetworkUse = true
            videoExportSession = exportSession
            if exportSession.export() {
                videoExportSession = nil
                setVideoAtPath(outputPath)
            }
        }
    }
    
    func setVideoFromRecordAtPath(path: String, completion: MutableAsset? -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] () -> Void in
            self?.setVideoFromRecordAtPath(path)
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                completion(self)
                })
            })
    }
    
    func saveToAssets() {
        PHPhotoLibrary.addAsset({ () -> PHAssetChangeRequest! in
            if self.type == .Video {
                return PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(NSURL(fileURLWithPath: self.original!))
            } else {
                return PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(NSURL(fileURLWithPath: self.original!))
            }
            }, collectionTitle: "meWrap", success: { () -> Void in
                
            }) { (error) -> Void in
        }
    }
    
    func saveToAssetsIfNeeded() {
        if canBeSavedToAssets && assetID == nil {
            saveToAssets()
        }
    }
    
    override var original: String? {
        didSet {
            if let oldOriginal = oldValue {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(oldOriginal)
                } catch {
                }
            }
        }
    }
    
    override var small: String? {
        didSet {
            if let oldSmall = oldValue {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(oldSmall)
                } catch {
                }
            }
        }
    }
    
    func uploadablePicture(justUploaded: Bool) -> Asset {
        uploaded = true
        let asset = Asset()
        asset.type = type
        asset.original = original
        asset.large = large
        asset.medium = medium
        asset.small = small
        asset.justUploaded = justUploaded
        return asset
    }
}

extension AVAssetExportSession {
    func export() -> Bool {
        let semaphore = dispatch_semaphore_create(0)
        exportAsynchronouslyWithCompletionHandler { () -> Void in
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return error == nil
    }
}

extension PHImageManager {
    func requestExportSessionForVideo(asset: PHAsset, options: PHVideoRequestOptions, exportPreset: String) -> AVAssetExportSession? {
        var session: AVAssetExportSession?
        let semaphore = dispatch_semaphore_create(0)
        requestExportSessionForVideo(asset, options: options, exportPreset: exportPreset) { (s, info) -> Void in
            session = s
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return session
    }
}
