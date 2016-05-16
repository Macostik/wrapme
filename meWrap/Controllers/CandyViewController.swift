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
    
    internal let imageView = ImageView()
    internal let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
    internal lazy var errorLabel: Label = specify(Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())) { label in
        label.numberOfLines = 0
        label.text = "no_internet_connection".ls
        self.view.addSubview(label)
        label.snp_makeConstraints {
            $0.centerX.equalTo(self.view)
            $0.centerY.equalTo(self.view).inset(-100)
            $0.width.equalTo(256)
        }
    }
    
    override func loadView() {
        super.loadView()
        view.addSubview(spinner)
        spinner.hidesWhenStopped = true
        spinner.hidden = true
        spinner.snp_makeConstraints {
            $0.center.equalTo(view)
        }
        Candy.notifier().addReceiver(self)
        candy?.fetch(nil, failure:nil)
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
    
    let scrollView = UIScrollView()

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
        scrollView.bouncesZoom = false
        scrollView.frame = view.bounds
        scrollView.backgroundColor = UIColor.blackColor()
        imageView.frame = scrollView.bounds
        view.insertSubview(scrollView, belowSubview: spinner)
        scrollView.add(imageView) {
            $0.center.equalTo(scrollView)
            $0.size.equalTo(scrollView)
        }
        scrollView.minimumZoomScale = 1
        scrollView.zoomScale = 1
        scrollView.maximumZoomScale = 2
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
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
            scrollView.snp_remakeConstraints(closure: { (make) in
                make.center.equalTo(view)
                make.width.equalTo(view).priorityHigh()
                make.width.lessThanOrEqualTo(view)
                make.height.equalTo(view).priorityHigh()
                make.height.lessThanOrEqualTo(view)
                make.width.equalTo(scrollView.snp_height).multipliedBy(image.size.width / image.size.height)
            })
            scrollView.layoutIfNeeded()
            scrollView.zoomScale = 1
            scrollView.panGestureRecognizer.enabled = false
        }
    }
    
    func manager(manager: DeviceManager, didChangeOrientation orientation: UIDeviceOrientation) {
        scrollView.zoomScale = 1
        scrollView.panGestureRecognizer.enabled = false
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        scrollView.panGestureRecognizer.enabled = scale > scrollView.minimumZoomScale
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return candy?.mediaType == .Video || imageView.image == nil ? nil : imageView
    }
}

final class VideoCandyViewController: CandyViewController, VideoPlayerViewDelegate {
    
    let playerView = VideoPlayer()
    
    override func loadView() {
        super.loadView()
        playerView.player.muted = true
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
        view.insertSubview(imageView, belowSubview: spinner)
        view.insertSubview(playerView, belowSubview: spinner)
        imageView.snp_makeConstraints { $0.edges.equalTo(view) }
        playerView.snp_makeConstraints { $0.edges.equalTo(view) }
        
        playerView.tapped { [weak self] _ in
            self?.toggleVolume()
        }
    }
    
    func toggleVolume() {
        playerView.player.muted = !playerView.player.muted
        historyViewController?.volumeButton.selected = !playerView.player.muted
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
        guard !playerView.playing else { return }
        playerView.url = candy.asset?.videoURL()
    }
}
