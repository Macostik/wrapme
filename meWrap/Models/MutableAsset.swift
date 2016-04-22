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
    var comment: String?
    var canBeSavedToAssets: Bool = false
    var assetID: String?
    var date = NSDate.now()
    var edited = false
    var selected = false
    var uploaded = false
    var thumbnailSize: CGFloat = 240
    weak var videoExportSession: AVAssetExportSession?
    
    deinit {
        if !uploaded {
            let manager = NSFileManager.defaultManager()
            if let original = original {
                _ = try? manager.removeItemAtPath(original)
            }
            if let large = large where large != original {
                _ = try? manager.removeItemAtPath(large)
            }
            if let medium = medium {
                _ = try? manager.removeItemAtPath(medium)
            }
            if let small = small {
                _ = try? manager.removeItemAtPath(small)
            }
        }
    }
    
    convenience init(isAvatar: Bool) {
        let isPad = UI_USER_INTERFACE_IDIOM() == .Pad
        self.init(thumbnailSize: isPad ? (isAvatar ? 160 : 480) : (isAvatar ? 160 : 240))
    }
    
    convenience init(thumbnailSize: CGFloat) {
        self.init()
        self.thumbnailSize = thumbnailSize
    }
    
    func setImage(image: UIImage, isDowngrading: Bool = true) {
        let cache = ImageCache.uploadingCache
        cache.compressionQuality = isDowngrading ? 0.75 : 1.0
        let largePath = cache.getPath(cache.setImage(image))
        original = largePath
        large = largePath
        small = cache.getPath(cache.setImage(image.thumbnail(thumbnailSize)))
        medium = small
    }
    
    func setImage(image: UIImage, isDowngrading: Bool = true, completion: Void -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] () -> Void in
            self?.setImage(image, isDowngrading: isDowngrading)
            dispatch_async(dispatch_get_main_queue(), completion)
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
        } catch { }
    }
    
    func setVideoAtPath(path: String, completion: Void -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] () -> Void in
            self?.setVideoAtPath(path)
            dispatch_async(dispatch_get_main_queue(), completion)
            })
    }
    
    func setVideoFromAsset(asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.version = .Original
        options.deliveryMode = .MediumQualityFormat
        options.networkAccessAllowed = true
        if let session = PHImageManager.defaultManager().requestExportSessionForVideo(asset, options: options, exportPreset: AVAssetExportPresetMediumQuality) {
            var outputPath = "\(NSHomeDirectory())/Documents/Videos/"
            let manager = NSFileManager.defaultManager()
            _ = try? manager.createDirectoryAtPath(outputPath, withIntermediateDirectories: true, attributes: nil)
            outputPath = outputPath + ("\(NSProcessInfo.processInfo().globallyUniqueString).mp4")
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
    
    func setVideoFromAsset(asset: PHAsset, completion: Void -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] () -> Void in
            self?.setVideoFromAsset(asset)
            dispatch_async(dispatch_get_main_queue(), completion)
            })
    }
    
    func setVideoFromRecordAtPath(path: String) {
        let asset = AVAsset(URL: NSURL(fileURLWithPath: path))
        if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) {
            let name = GUID()
            let videosDirectoryPath = NSHomeDirectory() + "/Documents/Videos"
            _ = try? NSFileManager.defaultManager().createDirectoryAtPath(videosDirectoryPath, withIntermediateDirectories:true, attributes:nil)
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
    
    func setVideoFromRecordAtPath(path: String, completion: Void -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] () -> Void in
            self?.setVideoFromRecordAtPath(path)
            dispatch_async(dispatch_get_main_queue(), completion)
            })
    }
    
    func saveToAssets() {
        guard let url = original?.fileURL else { return }
        if self.type == .Video {
            PHPhotoLibrary.addVideoAtFileUrl(url, success: nil, failure: nil)
        } else {
            guard let image = UIImage(data: NSData(contentsOfURL: url)!) else { return }
            PHPhotoLibrary.addImage(image, success: nil, failure: nil)
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
                _ = try? NSFileManager.defaultManager().removeItemAtPath(oldOriginal)
            }
        }
    }
    
    override var small: String? {
        didSet {
            if let oldSmall = oldValue {
                _ = try? NSFileManager.defaultManager().removeItemAtPath(oldSmall)
            }
        }
    }
    
    func uploadableAsset() -> Asset {
        uploaded = true
        let asset = Asset()
        asset.type = type
        asset.original = original
        asset.large = large
        asset.medium = medium
        asset.small = small
        return asset
    }
}

extension AVAssetExportSession {
    func export() -> Bool {
        Dispatch.sleep({ (awake) in exportAsynchronouslyWithCompletionHandler { awake("") } })
        return error == nil
    }
}

extension PHImageManager {
    func requestExportSessionForVideo(asset: PHAsset, options: PHVideoRequestOptions, exportPreset: String) -> AVAssetExportSession? {
        return Dispatch.sleep({ (awake) in
            requestExportSessionForVideo(asset, options: options, exportPreset: exportPreset) { (session, info) -> Void in
                awake(session)
            }
        })
    }
}
