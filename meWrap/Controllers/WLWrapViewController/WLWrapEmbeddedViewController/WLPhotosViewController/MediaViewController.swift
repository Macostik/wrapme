//
//  MediaViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class HistoryDateSeparator: StreamReusableView {
    
    @IBOutlet weak var dateLabel: UILabel!
    
    override func setup(entry: AnyObject!) {
        if let item = entry as? HistoryItem {
            dateLabel.text = item.date.stringWithDateStyle(.MediumStyle)
        }
    }
}

class HistoryItemCell: StreamReusableView {
    
    class HistoryItemDataSource: StreamDataSource {
        func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            let x = targetContentOffset.memory.x
            let maxX = scrollView.maximumContentOffset.x
            if abs(x - maxX) <= 1 || abs(x) <= 1 {
                return
            }
            let point = CGPoint(x: x, y: scrollView.frame.midY)
            if var item = streamView?.itemPassingTest({ $0.frame.contains(point) }) {
                if (x - item.frame.origin.x) > item.frame.size.width/2 {
                    if let next = item.next {
                        item = next
                    }
                }
                targetContentOffset.memory.x = item.frame.origin.x
            }
        }
    }
    
    @IBOutlet weak var streamView: StreamView!
    
    private var dataSource: HistoryItemDataSource!
    
    private var candyMetrics: StreamMetrics!
    
    internal override func willEnqueue() {
        super.willEnqueue()
        (entry as? HistoryItem)?.offset = streamView.contentOffset
    }
    
    override func loadedWithMetrics(metrics: StreamMetrics!) {
        streamView.layout = SquareLayout(horizontal: true)
        dataSource = HistoryItemDataSource(streamView: streamView)
        candyMetrics = dataSource.addMetrics(StreamMetrics(identifier: "CandyCell"))
        candyMetrics.selection = metrics.selection
        dataSource.layoutSpacing = Constants.pixelSize
        candyMetrics.prepareAppearing = { [weak self] item, _ in
            item?.view?.transform = self?.streamView.transform ?? CGAffineTransformIdentity
        }
    }
    
    override func setup(entry: AnyObject!) {
        streamView.frame = bounds
        if let item = entry as? HistoryItem {
            let candies = item.candies
            if item.date.isToday() && candies.count >= 3 {
                streamView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                dataSource.items = candies.reverse()
            } else {
                streamView.transform = CGAffineTransformIdentity
                dataSource.items = candies
            }
            streamView.contentOffset = item.offset
        }
    }
}

class LiveBroadcastMediaView: StreamReusableView {
    
    @IBOutlet weak var imageView: ImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func setup(entry: AnyObject!) {
        if let broadcast = entry as? LiveBroadcast {
            nameLabel.text = "\(broadcast.broadcaster?.name ?? "") \("is_live_streaming".ls)"
            if let title = broadcast.title where !title.isEmpty {
                titleLabel?.text = broadcast.title
            } else {
                titleLabel?.text = "untitled".ls
            }
            imageView.url = broadcast.broadcaster?.avatar?.small
        }
    }
}

@objc protocol MediaViewControllerDelegate: WLWrapEmbeddedViewControllerDelegate {
    
    optional func mediaViewControllerDidAddPhoto(controller: MediaViewController)
    
}

class MediaViewController: WLWrapEmbeddedViewController {
    
    lazy var dataSource: MediaDataSource = MediaDataSource(streamView: self.streamView)
    @IBOutlet  weak var streamView: StreamView!
    @IBOutlet var primaryConstraint: LayoutPrioritizer!
    @IBOutlet weak var uploadingView: UploaderView!
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var liveButton: UIButton?
    
    var history: History!
    
    weak var candyMetrics: StreamMetrics!
    @IBOutlet weak var scrollDirectionPrioritizer: LayoutPrioritizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let wrap = wrap else {
            return
        }
        
        streamView.contentInset = streamView.scrollIndicatorInsets
        
        dataSource.scrollDirectionLayoutPrioritizer = self.scrollDirectionPrioritizer
        dataSource.numberOfGridColumns = 3;
        dataSource.layoutSpacing = Constants.pixelSize
        dataSource.autogeneratedPlaceholderMetrics.identifier = "media"
        
        if wrap.requiresFollowing && Network.sharedNetwork.reachable {
            wrap.candies = nil
        }
        
        dataSource.liveBroadcasts = { [weak wrap] _ in
            return wrap?.liveBroadcasts
        }
        let loader = IndexedStreamLoader(identifier: "MediaViews", index: 0)
        dataSource.liveBroadcastMetrics.loader = loader
        dataSource.liveBroadcastMetrics.selection = { [weak self] (item, broadcast) -> Void in
            if !Network.sharedNetwork.reachable {
                Toast.show("no_internet_connection".ls)
                return
            }
            if let controller = self?.storyboard?["liveBroadcast"] as? LiveBroadcastViewController {
                controller.wrap = self?.wrap
                if let broadcast = broadcast as? LiveBroadcast {
                    controller.broadcast = broadcast
                }
                self?.navigationController?.presentViewController(controller, animated: false, completion: nil)
            }
        }
        let dateMetrics = dataSource.addMetrics(StreamMetrics(loader: loader.loader(1)))
        dateMetrics.size = 42
        dateMetrics.selection = { [weak self] (item, entry) -> Void in
            if let controller = self?.storyboard?["historyItem"] as? HistoryItemViewController {
                controller.item = entry as? HistoryItem
                self?.navigationController?.pushViewController(controller, animated: false)
            }
        }
        
        candyMetrics = dataSource.addMetrics(StreamMetrics(loader: loader.loader(2)))
        candyMetrics.size = round(view.width / 2.5)
        candyMetrics.selectable = false
        candyMetrics.selection = { [weak self] (item, entry) -> Void in
            CandyEnlargingPresenter.handleCandySelection(item, entry: entry, historyItem: self?.history.itemWithCandy(entry as? Candy), dismissingView: { (presenter, candy) -> UIView? in
                return self?.enlargingPresenterDismissingView(candy)
            })
        }
        
        dataSource.appendableBlock = { [weak self] (dataSource) -> Bool in
            return self?.wrap?.uploaded ?? false
        }
        
        history = History(wrap: wrap)
        
        dataSource.setRefreshableWithStyle(.Orange)
        
        uploadingView.uploader = Uploader.candyUploader
        
        Network.sharedNetwork.addReceiver(self)
        
        if wrap.candies?.count > 0 {
            dataSource.paginatedSet?.newer(nil, failure: nil)
            dropDownCollectionView()
        }
        Wrap.notifier().addReceiver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        liveButton?.alpha = status == .Authorized || status == .NotDetermined ? 1 : 0.5
    }
    
    func enlargingPresenterDismissingView(candy: Candy) -> UIView? {
        guard let historyItems = history.entries as? [HistoryItem] else { return nil }
        guard let historyItem = historyItems.filter({ $0.candies.contains(candy) ?? false }).last else { return nil }
        guard let streamHistoryItem = streamView.itemPassingTest({ $0.entry === historyItem && $0.metrics == candyMetrics}) else { return nil }
        streamView.scrollRectToVisible(streamHistoryItem.frame, animated: true)
        guard let cell = streamHistoryItem.view as? HistoryItemCell else { return nil }
        guard let streamCandyItem = cell.streamView.itemPassingTest({ ($0.entry as? Candy) == candy}) else { return nil }
        cell.streamView.scrollRectToVisible(streamCandyItem.frame, animated: true)
        return streamCandyItem.view
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let wrap = wrap where wrap.valid else {
            Dispatch.mainQueue.after(0.5, block: { self.navigationController?.popViewControllerAnimated(false) })
            return
        }
        
        if let candies = wrap.candies as? Set<Candy> {
            for candy in candies where candy.valid {
                candy.markAsUnread(false)
            }
        }
        RecentUpdateList.sharedList.refreshCount({ [weak self] (_) -> Void in
            self?.badge?.value = RecentUpdateList.sharedList.unreadCandiesCountForWrap(wrap)
            }) { (_) -> Void in
        }
        dataSource.items = history
        uploadingView.update()
        streamView.unlock()
        if view.width > view.height {
            Dispatch.mainQueue.async { [weak self] _ in
                self?.dataSource.reload()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        streamView.lock()
    }
    
    private func dropDownCollectionView() {
        primaryConstraint.defaultState = false
        UIView.animateWithDuration(1, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.3, options: [], animations: { () -> Void in
            self.primaryConstraint.defaultState = true
            }, completion: nil)
    }
    
    @IBAction func addPhoto(sender: UIButton) {
        guard let wrap = wrap else {
            return
        }
        FollowingViewController.followWrapIfNeeded(wrap) { [weak self] () -> Void in
            if let controller = self {
                (controller.delegate as? MediaViewControllerDelegate)?.mediaViewControllerDidAddPhoto?(controller)
            }
        }
    }
    
    @IBAction func liveBroadcast(sender: UIButton) {
        if !Network.sharedNetwork.reachable {
            Toast.show("no_internet_connection".ls)
            return
        }
        guard wrap != nil else {
            return
        }
        
        let openLiveBroadcast: (Void -> Void) = {[weak self] () -> Void in
            FollowingViewController.followWrapIfNeeded(self!.wrap!) {
                if let controller = self, let liveBroadcastController = controller.storyboard?["liveBroadcast"] as? LiveBroadcastViewController {
                    liveBroadcastController.wrap = controller.wrap
                    controller.navigationController?.presentViewController(liveBroadcastController, animated: false, completion: nil)
                }
            }
        }
        
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch authorizationStatus {
        case .NotDetermined:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
                completionHandler: {(access) -> Void in
                    Dispatch.mainQueue.async {
                        if !access {
                            sender.alpha =  0.5
                            return
                        } else {
                            openLiveBroadcast()
                        }
                    }
            })
        case .Denied, .Restricted:
            sender.alpha = 0.5
            return
        default:
            openLiveBroadcast()
            sender.alpha = 1
            break
        }
    }
}

extension MediaViewController: NetworkNotifying {
    
    func networkDidChangeReachability(network: Network) {
        dataSource.reload()
    }
}

extension MediaViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if (event == .LiveBroadcastsChanged) {
            dataSource.reload()
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
}
