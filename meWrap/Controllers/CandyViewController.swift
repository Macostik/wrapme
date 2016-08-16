//
//  CandyViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class CandyViewController: BaseViewController, EntryNotifying {
    
    weak var candy: Candy?
    
    internal let imageView = ImageView(backgroundColor: UIColor.clearColor(), placeholder: ImageView.Placeholder(text: "t", size: 96, backgroundColor: UIColor.clearColor(), textColor: Color.grayLighter))
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
            if let controller = self where error?.isNetworkError == true {
                Network.network.subscribe(controller, block: { [unowned controller] reachable in
                    if let candy = controller.candy where reachable {
                        controller.errorLabel.hidden = true
                        controller.setup(candy)
                        Network.network.unsubscribe(controller)
                    }
                    })
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
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if let candy = candy where event == .Default {
            setup(candy)
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return candy == entry
    }
}

final class PhotoCandyViewController: CandyViewController, UIScrollViewDelegate {
    
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
        scrollView.backgroundColor = UIColor.blackColor()
        scrollView.frame = view.bounds
        view.insertSubview(scrollView, belowSubview: spinner)
        imageView.frame = scrollView.bounds
        scrollView.addSubview(imageView)
        scrollView.minimumZoomScale = 1
        scrollView.zoomScale = 1
        scrollView.maximumZoomScale = 2
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        if let recognizer = scrollView.pinchGestureRecognizer {
            scrollView.superview?.addGestureRecognizer(recognizer)
        }
        
        scrollView.panGestureRecognizer.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        scrollView.zoomScale = scrollView.minimumZoomScale
        super.viewWillAppear(animated)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ (_) in
            self.imageLoaded(self.imageView.image)
            }) { (_) in
                
        }
    }
    
    override func imageLoaded(image: UIImage?) {
        guard let image = image else { return }
        let rect = view.size.fit(image.size).rectCenteredInSize(view.size)
        if rect != scrollView.frame {
            scrollView.zoomScale = 1
            scrollView.frame = rect
            imageView.frame = scrollView.bounds
            scrollView.contentSize = imageView.size
            scrollView.panGestureRecognizer.enabled = false
        }
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        scrollView.panGestureRecognizer.enabled = scale > scrollView.minimumZoomScale
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView.image == nil ? nil : imageView
    }
}

final class VideoCandyViewController: CandyViewController {
    
    let playerView = VideoPlayer()
    
    override func loadView() {
        super.loadView()
        imageView.frame = view.bounds
        imageView.contentMode = .ScaleAspectFit
        imageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        imageView.backgroundColor = UIColor.blackColor()
        playerView.frame = view.bounds
        view.insertSubview(imageView, belowSubview: spinner)
        playerView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        imageView.userInteractionEnabled = true
        imageView.addSubview(playerView)
        playerView.replayButton.titleLabel?.font = .icons(32)
        view.add(playerView.replayButton) { (make) in
            make.center.equalTo(view)
        }
        view.add(playerView.spinner) { (make) in
            make.center.equalTo(view)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        CandyCell.videoPlayers.clear()
        playerView.startPlaying()
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
