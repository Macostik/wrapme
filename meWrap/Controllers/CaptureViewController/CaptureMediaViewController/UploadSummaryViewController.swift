//
//  UploadSummaryViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

protocol UploadSummaryViewControllerDelegate: class {
    func uploadSummaryViewController(controller: UploadSummaryViewController, didFinishWithAssets assets: [MutableAsset])
    func uploadSummaryViewController(controller: UploadSummaryViewController, didDeselectAsset asset: MutableAsset)
}

class UploadSummaryViewController: SwipeViewController<EditAssetViewController>, CaptureWrapContainer, VideoPlayerViewDelegate, ComposeBarDelegate {
    
    @IBOutlet weak var streamView: StreamView!
    
    lazy var dataSource: StreamDataSource<[MutableAsset]> = StreamDataSource(streamView: self.streamView)
    
    weak var asset: MutableAsset? {
        didSet {
            if let asset = asset {
                updateAssetData(asset)
            }
        }
    }
    
    var assets: [MutableAsset] = []
    
    @IBOutlet weak var composeBar: ComposeBar!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var videoPlayerView: VideoPlayerView!
    
    weak var delegate: UploadSummaryViewControllerDelegate?
    
    weak var wrap: Wrap? {
        didSet {
            if isViewLoaded() {
                setupWrapView(wrap)
            }
        }
    }
    
    weak var wrapView: WrapView? {
        didSet {
            setupWrapView(wrap)
        }
    }
    
    var changeWrap: (Void -> Void)?
    
    @IBAction func selectWrap(sender: UIButton) {
        changeWrap?()
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        streamView.layout = HorizontalStreamLayout()
        view.addGestureRecognizer(self.scrollView!.panGestureRecognizer)
        self.videoPlayerView.delegate = self
        let metrics = dataSource.addMetrics(StreamMetrics<EditAssetCell>(size: 92))
        metrics.selection = { [weak self] view in
            self?.setViewController(self?.editAssetViewControllerForAsset(view.entry), direction: .Forward, animated: false)
        }
        dataSource.items = assets
        streamView.scrollToItemPassingTest({ $0.position.index == (assets.count - 1) }, animated:false)
        setViewController(editAssetViewControllerForAsset(assets.last), direction: .Forward, animated: false)
    }
    
    override func requestAuthorizationForPresentingEntry(entry: Entry, completion: BooleanBlock) {
        UIAlertController.alert("unsaved_photo".ls, message: "leave_screen_on_editing".ls).action("cancel".ls, handler: { _ in
            completion(false)
        }).action("discard_changes".ls, handler: { _ in completion(true) }).show()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        dataSource.items = assets
        uploadButton.active = true
        uploadButton.setTitle((UploadWizardViewController.isActive ? "next" : "send").ls, forState: .Normal)
    }
    
    private func updateAssetData(asset: MutableAsset) {
        drawButton.hidden = asset.type == .Video
        editButton.hidden = drawButton.hidden
        composeBar.text = asset.comment
        if asset.type == .Video {
            videoPlayerView.url = asset.original?.fileURL
            videoPlayerView.hidden = false
        } else {
            videoPlayerView.url = nil
            videoPlayerView.hidden = true
        }
        assets.all({ $0.selected = $0 == asset })
        dataSource.reload()
        streamView.scrollToItemPassingTest({ $0.entry === asset }, animated:true)
    }
    
    func editAssetViewControllerForAsset(asset: MutableAsset?) -> EditAssetViewController? {
        guard let asset = asset else { return nil }
        return specify(EditAssetViewController(), { $0.asset = asset })
    }
    
    override func keyboardAdjustmentConstant(adjustment: KeyboardAdjustment, keyboard: Keyboard) -> CGFloat {
        return (keyboard.height - bottomView.height)
    }
    
    override func viewControllerNextTo(viewController: EditAssetViewController?, direction: SwipeDirection) -> EditAssetViewController? {
        guard let asset = viewController?.asset else { return nil }
        guard let index = assets.indexOf(asset) else { return nil }
        return editAssetViewControllerForAsset(assets[safe: direction == .Forward ? index + 1 : index - 1])
    }
    
    override func didChangeViewController(viewController: EditAssetViewController?) {
        if let asset = viewController?.asset {
            self.asset = asset
        }
    }
    
    private func back() {
        if #available(iOS 9.0, *) {
            navigationController?.popViewControllerAnimated(true)
        } else {
            navigationController?.popViewControllerAnimated(false)
        }
    }
    
    override func back(sender: UIButton?) {
        back()
    }
    
    @IBAction func upload(sender: AnyObject?) {
        asset?.comment = self.composeBar.text?.trim
        delegate?.uploadSummaryViewController(self, didFinishWithAssets:assets)
    }
    
    @IBAction func edit(sender: AnyObject?) {
        guard let image = viewController?.imageView.image else { return }
        let controller = ImageEditor.editControllerWithImage(image, completion: { [weak self] image in
            self?.editCurrentPictureWithImage(image)
            self?.navigationController?.popViewControllerAnimated(false)
            }, cancel: { [weak self] _ in
                self?.navigationController?.popViewControllerAnimated(false)
            })
        navigationController?.pushViewController(controller, animated:false)
    }
    
    private func editCurrentPictureWithImage(image: UIImage) {
        self.uploadButton.active = false
        asset?.setImage(image, completion:{ [weak self] _ in
            self?.asset?.edited = true
            self?.dataSource.reload()
            self?.uploadButton.active = true
            })
        viewController?.imageView.image = image
    }
    
    @IBAction func deletePicture(sender: AnyObject?) {
        guard let asset = asset, let index = assets.indexOf(asset) else { return }
        assets.removeAtIndex(index)
        delegate?.uploadSummaryViewController(self, didDeselectAsset:asset)
        if assets.count > 0 {
            dataSource.items = assets
            if index < assets.count {
                self.asset = assets[index]
                setViewController(editAssetViewControllerForAsset(self.asset), direction: .Forward, animated: true)
            } else {
                self.asset = assets[index - 1]
                setViewController(editAssetViewControllerForAsset(self.asset), direction: .Reverse, animated: true)
            }
        } else {
            back()
        }
    }
    
    @IBAction func draw(sender: AnyObject?) {
        composeBar.resignFirstResponder()
        guard let image = viewController?.imageView.image else { return }
        let drawingViewController = DrawingViewController()
        drawingViewController.setImage(image, finish: { [weak self] (image) -> Void in
            self?.editCurrentPictureWithImage(image)
            self?.dismissViewControllerAnimated(false, completion: nil)
        }) { [weak self] () -> Void in
            self?.dismissViewControllerAnimated(false, completion: nil)
        }
        presentViewController(drawingViewController, animated: false, completion: nil)
    }
    
    func videoPlayerViewDidPlay(view: VideoPlayerView) {
        scrollView!.panGestureRecognizer.enabled = false
    }
    
    func videoPlayerViewDidPause(view: VideoPlayerView) {
        scrollView!.panGestureRecognizer.enabled = true
    }
    
    @IBAction func composeBarDidFinish(sender: AnyObject) {
        composeBar.resignFirstResponder()
        composeBar.setDoneButtonHidden(true)
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        var comment = composeBar.text?.trim ?? ""
        while comment.utf8.count > InstanceCommentLimit {
            comment = comment.substringToIndex(comment.endIndex.predecessor())
        }
        if comment != composeBar.text?.trim {
            InfoToast.show("comment_limit".ls)
            composeBar.text = comment
        }
        asset?.comment = comment
        let item = streamView.itemPassingTest { $0.entry === asset }
        (item?.view as? EditAssetCell)?.updateStatus()
    }
    
    func composeBarDidBeginEditing(composeBar: ComposeBar) {
        scrollView?.userInteractionEnabled = false
    }
    
    func composeBarDidEndEditing(composeBar: ComposeBar) {
        asset?.comment = composeBar.text?.trim
        scrollView?.userInteractionEnabled = true
    }
}

private let InstanceCommentLimit = 1500
