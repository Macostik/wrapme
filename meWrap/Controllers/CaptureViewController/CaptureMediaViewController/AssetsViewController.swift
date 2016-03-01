//
//  AssetsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Photos
import SnapKit

class AssetCell: StreamReusableView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var acceptView: UIView!
    @IBOutlet weak var videoIndicator: UILabel!
    private var requestID: PHImageRequestID?
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let imageView = ImageView(backgroundColor: UIColor.clearColor())
        addSubview(imageView)
        self.imageView = imageView
        
        let videoIndicator = Label(icon: "+", size: 20)
        addSubview(videoIndicator)
        self.videoIndicator = videoIndicator
        
        let acceptView = UILabel()
        acceptView.textAlignment = .Center
        acceptView.backgroundColor = UIColor.whiteColor()
        acceptView.cornerRadius = 10
        acceptView.borderColor = Color.orange
        acceptView.borderWidth = 1
        acceptView.clipsToBounds = true
        acceptView.font = UIFont(name: "icons", size: 12)
        acceptView.textColor = Color.orange
        acceptView.text = "l"
        addSubview(acceptView)
        self.acceptView = acceptView
        
        imageView.snp_makeConstraints(closure: { $0.edges.equalTo(self) })
        videoIndicator.snp_makeConstraints(closure: {
            $0.top.equalTo(self).offset(2)
            $0.trailing.equalTo(self).offset(-2)
        })
        acceptView.snp_makeConstraints(closure: {
            $0.bottom.equalTo(self).offset(-2)
            $0.trailing.equalTo(self).offset(-2)
            $0.width.height.equalTo(20)
        })
    }
    
    override func willEnqueue() {
        imageView.image = nil
        if let requestID = requestID {
            PHImageManager.defaultManager().cancelImageRequest(requestID)
        }
    }
    
    private static var requestImageOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.synchronous = false
        options.networkAccessAllowed = true
        options.resizeMode = .Fast
        options.deliveryMode = .Opportunistic
        return options
    }()
    
    override func setup(entry: AnyObject?) {
        if let asset = entry as? PHAsset {
            let scale = UIScreen.mainScreen().scale
            let thumbnail = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let options = AssetCell.requestImageOptions
            requestID = PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: thumbnail, contentMode: .AspectFill, options: options, resultHandler: {[weak self] (image, info) -> Void in
                if let cell = self where (info?[PHImageResultRequestIDKey] as? NSNumber)?.intValue == cell.requestID {
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
    
    var isAvatar: Bool = false {
        didSet {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            if isAvatar {
                assets = PHAsset.fetchAssetsWithMediaType(.Image, options:options)
            } else {
                assets = PHAsset.fetchAssetsWithOptions(options)
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
    var assetsHidingHandler: (Void -> Void)?
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.layout = SquareLayout(streamView: streamView, horizontal: true)
        let dataSource = StreamDataSource(streamView: streamView)
        let metrics = StreamMetrics(loader: LayoutStreamLoader<AssetCell>())
        metrics.selection = { [weak self] (item, entry) in
            if let item = item, let asset = entry as? PHAsset {
                item.selected = self?.selectAsset(asset) ?? false
            }
        }
        metrics.prepareAppearing = { [weak self] (item, view) in
            if let asset = item.entry as? PHAsset {
                item.selected = self?.selectedAssets.contains(asset.localIdentifier) ?? false
                view.exclusiveTouch = self?.isAvatar ?? true
            }
        }
        
        dataSource.addMetrics(metrics)
        
        self.dataSource = dataSource
        
        self.streamView.panGestureRecognizer.addTarget(self, action: "scrollAssets")
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        token = 0;
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
        hideAssetsViewController()
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
    
    private var token: dispatch_once_t = 0
    
    func hideAssetsViewController() {
        dispatch_once(&token) { [weak self] in
            self!.assetsHidingHandler?()
        }
    }
    
    func scrollAssets() {
        hideAssetsViewController()
    }
}
