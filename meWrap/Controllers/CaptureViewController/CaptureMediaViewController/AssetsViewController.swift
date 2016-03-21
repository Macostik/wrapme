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
    
    var imageView = ImageView(backgroundColor: UIColor.clearColor())
    var acceptView = Label(icon: "l", size: 12, textColor: Color.orange)
    var videoIndicator = Label(icon: "+", size: 20)
    private var requestID: PHImageRequestID?
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        addSubview(imageView)
        addSubview(videoIndicator)
        acceptView.textAlignment = .Center
        acceptView.backgroundColor = UIColor.whiteColor()
        acceptView.cornerRadius = 10
        acceptView.borderColor = Color.orange
        acceptView.borderWidth = 1
        acceptView.clipsToBounds = true
        addSubview(acceptView)
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
    
    private static let requestImageOptions = specify(PHImageRequestOptions(), {
        $0.synchronous = false
        $0.networkAccessAllowed = true
        $0.resizeMode = .Fast
        $0.deliveryMode = .Opportunistic
    })
    
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
    
    var isAvatar: Bool = false
    
    weak var delegate: AssetsViewControllerDelegate?
    
    var assets: PHFetchResult?
    var selectedAssets = Set<String>()
    
    lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    let streamView = StreamView()
    var assetsHidingHandler: (Void -> Void)?
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func loadView() {
        super.loadView()
        view.addSubview(streamView)
        streamView.snp_makeConstraints { $0.edges.equalTo(view) }
        streamView.alwaysBounceHorizontal = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        streamView.layout = SquareLayout(streamView: streamView, horizontal: true)
        dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<AssetCell>()).change({ [weak self] metrics in
            metrics.selection = { (item, entry) in
                if let item = item, let asset = entry as? PHAsset {
                    item.selected = self?.selectAsset(asset) ?? false
                }
            }
            metrics.prepareAppearing = { (item, view) in
                if let asset = item.entry as? PHAsset {
                    item.selected = self?.selectedAssets.contains(asset.localIdentifier) ?? false
                    view.exclusiveTouch = self?.isAvatar ?? true
                }
            }
            }))
        
        streamView.panGestureRecognizer.addTarget(self, action: "hideAssetsViewController")
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        Dispatch.mainQueue.async {
            let options = specify(PHFetchOptions(), { $0.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)] })
            if self.isAvatar {
                self.assets = PHAsset.fetchAssetsWithMediaType(.Image, options:options)
            } else {
                self.assets = PHAsset.fetchAssetsWithOptions(options)
            }
            self.dataSource.items = self.assets
        }
    }
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let currentAssets = self.assets, let assets = changeInstance.changeDetailsForFetchResult(currentAssets)?.fetchResultAfterChanges {
                self.assets = assets
                self.dataSource.items = assets
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
    
    func hideAssetsViewController() {
        assetsHidingHandler?()
        assetsHidingHandler = nil
    }
}
