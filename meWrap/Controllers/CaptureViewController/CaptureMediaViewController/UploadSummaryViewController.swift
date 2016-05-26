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

class UploadSummaryViewController: SwipeViewController<EditAssetViewController>, CaptureWrapContainer, ComposeBarDelegate {
    
    private let streamView = StreamView()
    
    lazy var dataSource: StreamDataSource<[MutableAsset]> = StreamDataSource(streamView: self.streamView)
    
    weak var asset: MutableAsset? {
        didSet {
            if let asset = asset {
                updateAssetData(asset)
            }
        }
    }
    
    var assets: [MutableAsset] = []
    
    private let composeBar = ComposeBar()
    private let deleteButton = Button.expandableCandyAction("n")
    private let editButton = Button.candyAction("R", color: Color.blue, size: 24)
    private let uploadButton = Button(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    private let drawButton = Button.candyAction("8", color: Color.purple, size: 24)
    private weak var volumeButton: Button?
    
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
    
    private let blurredImageView = ImageView()
    
    override func loadView() {
        let view = UIView(frame: self.preferredViewFrame)
        self.view = view
        view.backgroundColor = UIColor.blackColor()
        view.add(streamView) { (make) in
            make.leading.trailing.bottom.equalTo(view)
            make.height.equalTo(110)
        }
        
        view.add(blurredImageView) { (make) in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(streamView.snp_top)
        }
        
        view.add(scrollView) { (make) in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(streamView.snp_top)
        }
        
        let topView = GradientView(startColor: UIColor(white: 0, alpha: 0.8), contentMode: .Top)
        view.add(topView) { (make) in
            make.leading.trailing.top.equalTo(view)
            make.height.equalTo(64)
        }
        
        let backButton = self.backButton(UIColor.whiteColor())
        topView.add(backButton) { (make) in
            make.leading.equalTo(topView).inset(8)
            make.centerY.equalTo(topView)
        }
        
        uploadButton.cornerRadius = 13
        uploadButton.backgroundColor = Color.orange
        uploadButton.normalColor = Color.orange
        uploadButton.highlightedColor = Color.orangeDark
        uploadButton.clipsToBounds = true
        uploadButton.setTitle("send".ls, forState: .Normal)
        uploadButton.addTarget(self, touchUpInside: #selector(self.upload(_:)))
        topView.add(uploadButton) { (make) in
            make.centerY.equalTo(topView)
            make.size.equalTo(CGSize(width: 54, height: 26))
            make.trailing.equalTo(topView).inset(8)
        }
        
        let wrapView = WrapView()
        wrapView.selectButton.addTarget(self, touchUpInside: #selector(self.selectWrap(_:)))
        self.wrapView = topView.add(wrapView) { (make) in
            make.leading.equalTo(backButton.snp_trailing).offset(12)
            make.trailing.lessThanOrEqualTo(uploadButton.snp_leading).inset(-8)
            make.top.bottom.equalTo(topView)
        }
        
        composeBar.delegate = self
        composeBar.textView.placeholder = "add_comment".ls
        composeBar.emojiButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        composeBar.doneButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        composeBar.doneButton.setTitle("E", forState: .Normal)
        view.add(composeBar) { (make) in
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(streamView.snp_top)
        }
        
        let gradient = GradientView(startColor: UIColor(white: 0, alpha: 0.8))
        view.insertSubview(gradient, belowSubview: composeBar)
        gradient.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(composeBar)
            make.height.equalTo(composeBar).offset(44)
        }
        
        deleteButton.backgroundColor = UIColor(white: 0, alpha: 0.8)
        deleteButton.addTarget(self, touchUpInside: #selector(self.deleteAsset(_:)))
        view.add(deleteButton) { (make) in
            make.size.equalTo(44)
            make.leading.equalTo(view).inset(10)
            make.bottom.equalTo(composeBar.snp_top).offset(-10)
        }
        
        editButton.addTarget(self, touchUpInside: #selector(self.edit(_:)))
        view.add(editButton) { (make) in
            make.size.equalTo(44)
            make.trailing.equalTo(view).inset(10)
            make.bottom.equalTo(composeBar.snp_top).inset(-10)
        }
        
        drawButton.addTarget(self, touchUpInside: #selector(self.draw(_:)))
        view.add(drawButton) { (make) in
            make.size.equalTo(44)
            make.trailing.equalTo(editButton.snp_leading).offset(-10)
            make.bottom.equalTo(composeBar.snp_top).inset(-10)
        }
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        blurredImageView.add(blurView) { $0.edges.equalTo(blurredImageView) }
        
        keyboardBottomGuideView = streamView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.layout = HorizontalStreamLayout()
        view.addGestureRecognizer(self.scrollView.panGestureRecognizer)
        let metrics = dataSource.addMetrics(StreamMetrics<EditAssetCell>(size: 92))
        metrics.selection = { [weak self] view in
            self?.setViewController(self?.editAssetViewControllerForAsset(view.entry), direction: .Forward, animated: false)
        }
        dataSource.items = assets
        streamView.scrollToItemPassingTest({ $0.position.index == (assets.count - 1) }, animated:false)
        setViewController(editAssetViewControllerForAsset(assets.last), direction: .Forward, animated: false)
    }
    
    override func requestAuthorizationForPresentingEntry(entry: Entry, completion: BooleanBlock) {
        UIAlertController.alert("unsaved_media".ls, message: "leave_screen_on_editing".ls).action("cancel".ls, handler: { _ in
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
        blurredImageView.url = asset.small
        let isVideo = asset.type == .Video
        drawButton.hidden = isVideo
        editButton.hidden = drawButton.hidden
        composeBar.text = asset.comment
        volumeButton?.removeFromSuperview()
        if let viewController = viewController where viewController.asset == asset && isVideo {
            view.add(viewController.videoPlayer.volumeButton) { (make) in
                make.trailing.equalTo(view).inset(10)
                make.bottom.equalTo(composeBar.snp_top).inset(-10)
                make.size.equalTo(44)
            }
            self.volumeButton = viewController.videoPlayer.volumeButton
        }
        assets.all({ $0.selected = $0 == asset })
        dataSource.reload()
        streamView.scrollToItemPassingTest({ $0.entry === asset }, animated:true)
    }
    
    func editAssetViewControllerForAsset(asset: MutableAsset?) -> EditAssetViewController? {
        guard let asset = asset else { return nil }
        return specify(EditAssetViewController(), { $0.asset = asset })
    }
    
    override func keyboardBottomGuideViewAdjustment(keyboard: Keyboard) -> CGFloat {
        return (keyboard.height - streamView.height)
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
    
    @IBAction func deleteAsset(sender: AnyObject?) {
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
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        composeBar.resignFirstResponder()
        composeBar.setDoneButtonHidden(true, animated: true)
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        var comment = composeBar.text?.trim ?? ""
        while comment.utf8.count > InstanceCommentLimit {
            comment = comment.substringToIndex(comment.endIndex.predecessor())
        }
        if comment != composeBar.text?.trim {
            Toast.show("comment_limit".ls)
            composeBar.text = comment
        }
        asset?.comment = comment
        let item = streamView.itemPassingTest { $0.entry === asset }
        (item?.view as? EditAssetCell)?.updateStatus()
    }
    
    func composeBarDidBeginEditing(composeBar: ComposeBar) {
        scrollView.scrollEnabled = false
    }
    
    func composeBarDidEndEditing(composeBar: ComposeBar) {
        asset?.comment = composeBar.text?.trim
        scrollView.scrollEnabled = true
    }
}

private let InstanceCommentLimit = 1500
