//
//  CandyViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class CandyViewController: BaseViewController {
    
    weak var candy: Candy?
    
    weak var historyViewController: HistoryViewController?
    
    @IBOutlet weak var imageView: ImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var aspectRatioConstraint: NSLayoutConstraint?
    @IBOutlet weak var videoPlayerView: VideoPlayerView?
    private var slideInteractiveTransition: SlideInteractiveTransition?
    
    deinit {
        scrollView?.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let scrollView = scrollView {
            scrollView.userInteractionEnabled = false
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 2
            scrollView.superview?.addGestureRecognizer(scrollView.panGestureRecognizer)
            if let recognizer = scrollView.pinchGestureRecognizer {
                scrollView.superview?.addGestureRecognizer(recognizer)
            }
            
            scrollView.panGestureRecognizer.enabled = false
            
            DeviceManager.defaultManager.addReceiver(self)
        }
        
        Candy.notifier().addReceiver(self)
        
        videoPlayerView?.delegate = self
        
        candy?.fetch(nil, failure:nil)
        slideInteractiveTransition = SlideInteractiveTransition(contentView:contentView, imageView:imageView)
        slideInteractiveTransition?.delegate = self
    }
    
    override func shouldUsePreferredViewFrame() -> Bool {
        return false
    }
    
    private func setup(candy: Candy) {
        self.spinner.hidden = false
        self.errorLabel.hidden = true
        
        if candy.mediaType == .Video {
            if let playerView = videoPlayerView {
                if !playerView.playing {
                    if let original = candy.asset?.original {
                        if original.isExistingFilePath {
                            playerView.url = original.fileURL
                        } else {
                            let path = ImageCache.defaultCache.getPath(ImageCache.uidFromURL(original)) + ".mp4"
                            if path.isExistingFilePath {
                                playerView.url = path.fileURL
                            } else {
                                playerView.url = original.URL
                            }
                        }
                    }
                }
            }
        }
        
        imageView.setURL(candy.asset?.large, success: { [weak self] (image, cached) -> Void in
            if candy.mediaType == .Photo {
                self?.calculateScaleValues()
                self?.scrollView?.userInteractionEnabled = true
            }
            self?.spinner.hidden = true
            self?.errorLabel.hidden = true
            }) { [weak self] (error) -> Void in
                if error?.isNetworkError == true {
                    Network.sharedNetwork.addReceiver(self)
                    self?.errorLabel.hidden = false
                } else {
                    self?.errorLabel.hidden = true
                }
                self?.spinner.hidden = true
        }
    }
    
    private func calculateScaleValues() {
        if let image = imageView.image, let scrollView = scrollView, let constraint = aspectRatioConstraint {
            let _constraint = NSLayoutConstraint(item:constraint.firstItem, attribute:constraint.firstAttribute, relatedBy:constraint.relation, toItem:constraint.secondItem, attribute:constraint.secondAttribute, multiplier:image.size.width/image.size.height, constant:0)
            scrollView.removeConstraint(constraint)
            scrollView.addConstraint(_constraint)
            aspectRatioConstraint = _constraint
            scrollView.layoutIfNeeded()
            scrollView.zoomScale = 1
            scrollView.panGestureRecognizer.enabled = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let scrollView = scrollView {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
        if let candy = candy {
            setup(candy)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let candy = candy {
            if let videoPlayerView = videoPlayerView {
                let shouldBeShow = candy.isVideo && !(videoPlayerView.spinner?.isAnimating() ?? false)
                videoPlayerView.placeholderPlayButton?.hidden = !shouldBeShow
                videoPlayerView.playButton?.hidden = !shouldBeShow
                videoPlayerView.secondaryPlayButton?.hidden = true
                videoPlayerView.timeView.hidden = true
                videoPlayerView.timeViewPrioritizer?.defaultState = !(candy.latestComment?.text?.isEmpty ?? true)
            }
        }
    }
    
    func hideAllViews() {
        videoPlayerView?.hiddenCenterViews(true)
        videoPlayerView?.hiddenBottomViews(true)
        historyViewController?.hideSecondaryViews(true)
    }
}

extension CandyViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if let candy = candy {
            videoPlayerView?.timeViewPrioritizer?.defaultState = !(candy.latestComment?.text?.isEmpty ?? true)
            if event == .Default {
                setup(candy)
            }
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return candy == entry
    }
}

extension CandyViewController: VideoPlayerViewDelegate {
    
    func videoPlayerViewDidPlay(view: VideoPlayerView) {
        slideInteractiveTransition?.panGestureRecognizer.enabled = false
        historyViewController?.scrollView.panGestureRecognizer.enabled = false
        historyViewController?.setBarsHidden(false, animated:true)
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:#selector(CandyViewController.hideAllViews), object:nil)
        performSelector(#selector(CandyViewController.hideAllViews), withObject:nil, afterDelay:4)
    }
    
    func videoPlayerViewDidPause(view: VideoPlayerView) {
        historyViewController?.commentPressed = {
            view.pause()
        }
        historyViewController?.hideSecondaryViews(false)
        slideInteractiveTransition?.panGestureRecognizer.enabled = true
        historyViewController?.scrollView.panGestureRecognizer.enabled = true
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:#selector(CandyViewController.hideAllViews), object:nil)
    }
    
    func videoPlayerViewSeekedToTime(view: VideoPlayerView) {
        if view.playing {
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:#selector(CandyViewController.hideAllViews), object:nil)
            performSelector(#selector(CandyViewController.hideAllViews), withObject:nil, afterDelay:4)
        }
    }
    
    func videoPlayerViewDidPlayToEnd(view: VideoPlayerView) {
        historyViewController?.hideSecondaryViews(false)
        slideInteractiveTransition?.panGestureRecognizer.enabled = true
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:#selector(CandyViewController.hideAllViews), object:nil)
    }
}

extension CandyViewController: SlideInteractiveTransitionDelegate {
    
    func slideInteractiveTransition(controller: SlideInteractiveTransition, hideViews: Bool) {
        if let videoPlayerView = self.videoPlayerView {
            videoPlayerView.timeView.hidden = hideViews || !(videoPlayerView.playButton?.hidden ?? true)
            videoPlayerView.secondaryPlayButton?.hidden = videoPlayerView.timeView.hidden
            videoPlayerView.timeView.addAnimation(CATransition.transition(kCATransitionFade))
            videoPlayerView.secondaryPlayButton?.addAnimation(CATransition.transition(kCATransitionFade))
        }
        historyViewController?.hideSecondaryViews(hideViews)
    }
    
    func slideInteractiveTransitionSnapshotView(controller: SlideInteractiveTransition) -> UIView? {
        guard let controller = historyViewController else { return nil }
        guard let controllers = controller.navigationController?.viewControllers else { return nil }
        guard let index = controllers.indexOf(controller) else { return nil }
        return controllers[safe: index - 1]?.view
    }
    
    func slideInteractiveTransitionDidFinish(controller: SlideInteractiveTransition) {
        historyViewController?.navigationController?.popViewControllerAnimated(false)
    }
    
    func slideInteractiveTransitionPresentingView(controller: SlideInteractiveTransition) -> UIView? {
        guard let candy = candy else { return nil }
        let dismissingView = historyViewController?.dismissingView?(presenter: nil, candy: candy)
        dismissingView?.alpha = 0
        return dismissingView
    }
}

extension CandyViewController: DeviceManagerNotifying {
    
    func manager(manager: DeviceManager, didChangeOrientation orientation: UIDeviceOrientation) {
        scrollView?.zoomScale = 1
        scrollView?.panGestureRecognizer.enabled = false
    }
}

extension CandyViewController: UIScrollViewDelegate {
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        slideInteractiveTransition?.panGestureRecognizer.enabled = scrollView.zoomScale == 1
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        scrollView.panGestureRecognizer.enabled = scale > scrollView.minimumZoomScale
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return candy?.mediaType == .Video ? nil : imageView
    }
}

extension CandyViewController: NetworkNotifying {
    
    func networkDidChangeReachability(network: Network) {
        if let candy = candy where network.reachable {
            setup(candy)
            network.removeReceiver(self)
        }
    }
}

extension CandyViewController {
    
    @IBAction func shareButtonClicked(sender: Button) {
        sender.loading = true
        let completion: ObjectBlock = {[weak self]  item in
            let activityVC = UIActivityViewController(activityItems: [item!], applicationActivities: nil)
            self?.presentViewController(activityVC, animated: true, completion: nil)
            sender.loading = false
        }
        if candy?.isVideo == true {
            let urlData = NSData(contentsOfURL: NSURL(string: candy?.asset?.original ?? "") ?? NSURL())
            let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let filePath = "\(path)/tmpVideo.mov"
            urlData?.writeToFile(filePath, atomically: true)
            let videoLink = NSURL(fileURLWithPath: filePath) 
            completion(videoLink)
           
        } else {
            BlockImageFetching.enqueue(self.candy?.asset?.original ?? "", success: { (image) -> Void in
                 completion(image)
                }, failure: nil)
        }
    }
}
