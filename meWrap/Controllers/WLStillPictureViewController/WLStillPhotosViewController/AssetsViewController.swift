//
//  AssetsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Photos

class AssetCell: StreamReusableView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var acceptView: UIView!
    @IBOutlet weak var videoIndicator: UILabel!
    private var requestID: PHImageRequestID?
    
    override func willEnqueue() {
        if let requestID = requestID {
            PHImageManager.defaultManager().cancelImageRequest(requestID)
        }
    }
    
    private static var requestImageOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.synchronous = false
        options.networkAccessAllowed = true
        options.resizeMode = .Exact
        options.deliveryMode = .HighQualityFormat
        return options
    }()
    
    override func setup(entry: AnyObject!) {
        if let asset = entry as? PHAsset {
            let scale = UIScreen.mainScreen().scale
            let thumbnail = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let options = AssetCell.requestImageOptions
            requestID = PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: thumbnail, contentMode: .AspectFill, options: options, resultHandler: {[weak self] (image, info) -> Void in
                if let cell = self, let requestID = (info?[PHImageResultRequestIDKey] as? NSNumber)?.intValue where requestID == cell.requestID {
                    cell.requestID = nil
                    cell.imageView.image = image
                }
                })
            videoIndicator.hidden = asset.mediaType != .Video
        }
    }
    
    override var selected: Bool {
        didSet {
            backgroundColor = selected ? UIColor.whiteColor() : UIColor.clearColor()
            acceptView.hidden = !selected
            imageView.alpha = selected ? 0.5 : 1.0
        }
    }
}

extension PHFetchResult: BaseOrderedContainer {
    public func tryAt(index: Int) -> AnyObject? {
        if (index >= 0 && index < count) {
            return objectAtIndex(index)
        } else {
            return nil
        }
    }
}

@objc protocol AssetsViewControllerDelegate {
    
    optional func assetsViewController(controller: AssetsViewController, shouldSelectAsset asset: PHAsset) -> Bool
    
    optional func assetsViewController(controller: AssetsViewController, didSelectAsset asset: PHAsset)
    
    optional func assetsViewController(controller: AssetsViewController, didDeselectAsset asset: PHAsset)
    
}

class AssetsViewController: UIViewController, PHPhotoLibraryChangeObserver {
    
    var mode: StillPictureMode = .Default {
        didSet {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            if mode == .Default {
                assets = PHAsset.fetchAssetsWithOptions(options)
            } else {
                assets = PHAsset.fetchAssetsWithMediaType(.Image, options:options)
            }
            dataSource?.items = assets
        }
    }
    
    weak var delegate: AssetsViewControllerDelegate?
    
    var assets: PHFetchResult?
    var selectedAssets = Set<String>()
    
    var dataSource: StreamDataSource?
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var accessErrorLabel: UILabel!
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.layout = SquareLayout(horizontal: true)
        let dataSource = StreamDataSource(streamView: streamView)
        let metrics = StreamMetrics(identifier: "AssetCell")
        metrics.selection = { [weak self] (item, entry) in
            if let asset = entry as? PHAsset, let item = item {
                item.selected = self?.selectAsset(asset) ?? false
            }
        }
        metrics.prepareAppearing = { [weak self] (item, entry) in
            if let asset = entry as? PHAsset, let item = item {
                item.selected = self?.selectedAssets.contains(asset.localIdentifier) ?? false
                item.view?.exclusiveTouch = self?.mode != .Default
            }
        }
        
        dataSource.addMetrics(metrics)
        dataSource.numberOfGridColumns = 1
        dataSource.sizeForGridColumns = 1
        dataSource.layoutSpacing = 3
        
        self.dataSource = dataSource
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let currentAssets = self.assets, let assets = changeInstance.changeDetailsForFetchResult(currentAssets)?.fetchResultAfterChanges {
                self.assets = assets
                self.dataSource?.items = assets
            }
        }
    }
    
    func selectAsset(asset: PHAsset) -> Bool {
        let identifier = asset.localIdentifier
        if selectedAssets.contains(identifier) {
            selectedAssets.remove(identifier)
            delegate?.assetsViewController?(self, didDeselectAsset:asset)
        } else {
            if delegate?.assetsViewController?(self, shouldSelectAsset:asset) ?? true {
                selectedAssets.insert(identifier)
                delegate?.assetsViewController?(self, didSelectAsset:asset)
                return true
            }
        }
        return false
    }
    
}
