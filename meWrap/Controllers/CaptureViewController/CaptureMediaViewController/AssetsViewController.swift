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

extension UIDeviceOrientation {
    
    func interfaceTransform() -> CGAffineTransform {
        switch self {
        case .LandscapeLeft: return CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        case .LandscapeRight: return CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        case .PortraitUpsideDown: return CGAffineTransformMakeRotation(CGFloat(M_PI))
        default: return CGAffineTransformIdentity
        }
    }
}

class AssetCell: EntryStreamReusableView<PHAsset> {
    
    var imageView = ImageView(backgroundColor: UIColor.clearColor())
    var acceptView = Label(icon: "E", size: 12, textColor: Color.orange)
    var videoIndicator = Label(icon: "+", size: 20)
    private var requestID: PHImageRequestID?
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        addSubview(imageView)
        addSubview(videoIndicator)
        acceptView.textAlignment = .Center
        acceptView.backgroundColor = UIColor.whiteColor()
        acceptView.cornerRadius = 10
        acceptView.setBorder(color: Color.orange)
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
        DeviceManager.defaultManager.subscribe(self) { [unowned self] orientation in
            animate(animations: { 
                self.transform = orientation.interfaceTransform()
            })
        }
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
    
    override func setup(asset: PHAsset) {
        let scale = UIScreen.mainScreen().scale
        let thumbnail = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let options = AssetCell.requestImageOptions
        requestID = PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: thumbnail, contentMode: .AspectFill, options: options, resultHandler: {[weak self] (image, info) -> Void in
            if let cell = self where (info?[PHImageResultRequestIDKey] as? NSNumber)?.intValue == cell.requestID {
                cell.imageView.image = image
            }
            })
        videoIndicator.hidden = asset.mediaType != .Video
        transform = DeviceManager.defaultManager.orientation.interfaceTransform()
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
    @nonobjc subscript (safe index: Int) -> PHAsset? {
        if (index >= 0 && index < count) {
            return objectAtIndex(index) as? PHAsset
        } else {
            return nil
        }
    }
}

protocol AssetsViewControllerDelegate: class {
    func assetsViewController(controller: AssetsViewController, shouldSelectAsset asset: PHAsset) -> Bool
    func assetsViewController(controller: AssetsViewController, didSelectAsset asset: PHAsset)
    func assetsViewController(controller: AssetsViewController, didDeselectAsset asset: PHAsset)
}

class AssetsViewController: UIViewController, PHPhotoLibraryChangeObserver {
    
    var isAvatar: Bool = false
    
    weak var delegate: AssetsViewControllerDelegate?
    
    var assets: PHFetchResult?
    var selectedAssets = Set<String>()
    
    lazy var dataSource: StreamDataSource<PHFetchResult> = StreamDataSource(streamView: self.streamView)
    let streamView = StreamView()
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    private let arrow = Label(icon: "\"", size: 20)
    private let container = UIView()
    
    convenience init(panningView: UIView) {
        self.init(nibName: nil, bundle: nil)
        panningView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.panning(_:))))
    }
    
    private var heightConstraint: Constraint!
    
    override func loadView() {
        super.loadView()
        view.clipsToBounds = true
        let interactionView = UIView()
        interactionView.clipsToBounds = true
        view.add(interactionView) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(24)
        }
        
        let arrowView = UIView()
        arrowView.backgroundColor = Color.orange
        arrowView.clipsToBounds = true
        arrowView.cornerRadius = 4
        interactionView.add(arrowView) { (make) in
            make.centerX.top.equalTo(interactionView)
            make.size.equalTo(CGSize(width: 36, height: 32))
        }
        interactionView.add(arrow) { (make) in
            make.center.equalTo(interactionView)
        }
        if hiddenByDefault {
            arrow.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI), 1, 0, 0)
        }
        
        let actionButton = Button(type: .Custom)
        actionButton.addTarget(self, touchUpInside: #selector(self.toggle(_:)))
        interactionView.add(actionButton) { (make) in
            make.edges.equalTo(interactionView)
        }
        
        container.clipsToBounds = true
        view.add(container) {
            $0.top.equalTo(interactionView.snp_bottom)
            $0.leading.trailing.bottom.equalTo(view)
            heightConstraint = $0.height.equalTo(view.snp_width).offset(hiddenByDefault ? -Constants.screenWidth * 0.25 : 0).multipliedBy(0.25).constraint
        }
        container.add(streamView) {
            $0.leading.top.trailing.equalTo(container)
            $0.height.equalTo(view.snp_width).multipliedBy(0.25)
        }
        container.add(specify(UIView(), {
            $0.backgroundColor = Color.orange
        })) { (make) in
            make.leading.top.trailing.equalTo(container)
            make.height.equalTo(1)
        }
        container.add(specify(UIView(), {
            $0.backgroundColor = Color.orange
        })) { (make) in
            make.leading.bottom.trailing.equalTo(container)
            make.height.equalTo(1)
        }
        streamView.alwaysBounceHorizontal = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        streamView.layout = HorizontalSquareLayout()
        dataSource.addMetrics(StreamMetrics<AssetCell>().change({ [weak self] metrics in
            metrics.selection = { view in
                if let item = view.item, let asset = view.entry {
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
        
        streamView.panGestureRecognizer.addTarget(self, action: #selector(self.cancelAutoHide))
        
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
    
    @objc private func panning(sender: UIPanGestureRecognizer) {
        let minHeight = -streamView.height
        var offset = (container.height - streamView.height)
        if (sender.state == .Changed) {
            let translation = sender.translationInView(sender.view)
            offset = smoothstep(minHeight, 0, offset - translation.y / 2)
            heightConstraint.updateOffset(offset)
            arrow.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI) * offset / minHeight, 1, 0, 0)
            view.superview?.layoutIfNeeded()
            sender.setTranslation(CGPointZero, inView: sender.view)
        } else if (sender.state == .Ended || sender.state == .Cancelled) {
            let velocity = sender.velocityInView(sender.view).y
            if abs(velocity) > 500 {
                setHidden(velocity > 0, animated: true)
            } else {
                setHidden(offset < minHeight/2, animated: true)
            }
        }
    }
    
    @objc private func toggle(sender: AnyObject?) {
        setHidden(container.height != 0, animated: true)
    }
    
    func hide() {
        setHidden(true, animated: true)
    }
    
    func enqueueAutoHide() {
        enqueueSelector(#selector(self.hide), delay: 3.0)
    }
    
    var hiddenByDefault = false
    
    func setHidden(hidden: Bool, animated: Bool) {
        cancelAutoHide()
        heightConstraint.updateOffset(hidden ? -Constants.screenWidth * 0.25 : 0)
        UIView.animateWithDuration(animated ? 0.3 : 0) {
            if (hidden) {
                self.arrow.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI), 1, 0, 0)
            } else {
                self.arrow.layer.transform = CATransform3DIdentity
            }
            self.view.superview?.layoutIfNeeded()
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
        cancelAutoHide()
        let identifier = asset.localIdentifier
        if selectedAssets.contains(identifier) {
            selectedAssets.remove(identifier)
            delegate?.assetsViewController(self, didDeselectAsset:asset)
        } else {
            if delegate?.assetsViewController(self, shouldSelectAsset:asset) ?? true {
                selectedAssets.insert(identifier)
                delegate?.assetsViewController(self, didSelectAsset:asset)
                return true
            }
        }
        return false
    }
    
    func cancelAutoHide() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(self.hide), object: nil)
    }
}
