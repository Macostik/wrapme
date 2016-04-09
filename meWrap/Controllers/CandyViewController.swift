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
    
    internal let contentView = UIView()
    internal let imageView = ImageView()
    internal let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
    internal lazy var errorLabel: Label = specify(Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())) { label in
        label.numberOfLines = 0
        label.text = "no_internet_connection".ls
        self.contentView.addSubview(label)
        label.snp_makeConstraints {
            $0.centerX.equalTo(self.contentView)
            $0.centerY.equalTo(self.contentView).inset(-100)
            $0.width.equalTo(256)
        }
    }
    private var slideInteractiveTransition: SlideInteractiveTransition?
    
    override func loadView() {
        super.loadView()
        view.addSubview(contentView)
        contentView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
        contentView.addSubview(spinner)
        spinner.hidesWhenStopped = true
        spinner.hidden = true
        spinner.snp_makeConstraints {
            $0.center.equalTo(contentView)
        }
        Candy.notifier().addReceiver(self)
        candy?.fetch(nil, failure:nil)
        slideInteractiveTransition = SlideInteractiveTransition(contentView:contentView, imageView:imageView)
        slideInteractiveTransition?.delegate = self
        if let historyViewController = historyViewController {
            slideInteractiveTransition?.panGestureRecognizer.requireGestureRecognizerToFail(historyViewController.swipeUpGesture)
            slideInteractiveTransition?.panGestureRecognizer.requireGestureRecognizerToFail(historyViewController.swipeDownGesture)
        }
    }
    
    internal func setup(candy: Candy) {
        self.spinner.startAnimating()
        imageView.setURL(candy.asset?.large, success: { [weak self] (image, cached) -> Void in
            self?.imageLoaded(image)
            self?.spinner.stopAnimating()
            }) { [weak self] (error) -> Void in
                if error?.isNetworkError == true {
                    Network.sharedNetwork.addReceiver(self)
                    self?.errorLabel.hidden = false
                }
                self?.spinner.stopAnimating()
        }
    }
    
    internal func imageLoaded(image: UIImage?) {}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let candy = candy {
            setup(candy)
        }
    }
}

extension CandyViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if let candy = candy {
            if event == .Default {
                setup(candy)
            }
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return candy == entry
    }
}

extension CandyViewController: SlideInteractiveTransitionDelegate {
    
    func slideInteractiveTransition(controller: SlideInteractiveTransition, hideViews: Bool) {
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

extension CandyViewController: NetworkNotifying {
    
    func networkDidChangeReachability(network: Network) {
        if let candy = candy where network.reachable {
            errorLabel.hidden = true
            setup(candy)
            network.removeReceiver(self)
        }
    }
}

final class PhotoCandyViewController: CandyViewController, DeviceManagerNotifying, UIScrollViewDelegate {
    
    private let scrollView = UIScrollView()
    
    deinit {
        scrollView.delegate = nil
    }
    
    override func loadView() {
        super.loadView()
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        contentView.insertSubview(scrollView, belowSubview: spinner)
        scrollView.addSubview(imageView)
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 2
        contentView.addGestureRecognizer(scrollView.panGestureRecognizer)
        if let recognizer = scrollView.pinchGestureRecognizer {
            scrollView.superview?.addGestureRecognizer(recognizer)
        }
        
        scrollView.panGestureRecognizer.enabled = false
        
        DeviceManager.defaultManager.addReceiver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        scrollView.zoomScale = scrollView.minimumZoomScale
        super.viewWillAppear(animated)
    }
    
    override func imageLoaded(image: UIImage?) {
        if let image = image {
            scrollView.frame = contentView.size.fit(image.size).rectCenteredInSize(contentView.size)
            imageView.frame = scrollView.bounds
            scrollView.zoomScale = 1
            scrollView.panGestureRecognizer.enabled = false
        }
    }
    
    func manager(manager: DeviceManager, didChangeOrientation orientation: UIDeviceOrientation) {
        scrollView.zoomScale = 1
        scrollView.panGestureRecognizer.enabled = false
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        slideInteractiveTransition?.panGestureRecognizer.enabled = scrollView.zoomScale == 1
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        scrollView.panGestureRecognizer.enabled = scale > scrollView.minimumZoomScale
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return candy?.mediaType == .Video || imageView.image == nil ? nil : imageView
    }
}

final class VideoCandyViewController: CandyViewController, VideoPlayerViewDelegate {
    
    private let playerView = VideoPlayer()
    
    override func loadView() {
        super.loadView()
        imageView.contentMode = .ScaleAspectFit
        playerView.playbackLikelyToKeepUp = { [weak self] keepUp in
            if keepUp {
                self?.spinner.stopAnimating()
            } else {
                self?.spinner.startAnimating()
            }
        }
        playerView.didPlayToEnd = { [weak self] _ in
            self?.playerView.playing = true
        }
        contentView.insertSubview(imageView, belowSubview: spinner)
        contentView.insertSubview(playerView, belowSubview: spinner)
        imageView.snp_makeConstraints { $0.edges.equalTo(contentView) }
        playerView.snp_makeConstraints { $0.edges.equalTo(contentView) }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        playerView.playing = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        playerView.playing = false
    }
    
    internal override func setup(candy: Candy) {
        super.setup(candy)
        guard let original = candy.asset?.original where !playerView.playing else { return }
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
