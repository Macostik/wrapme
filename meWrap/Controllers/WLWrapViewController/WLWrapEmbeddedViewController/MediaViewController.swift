//
//  MediaViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class HistoryDateSeparator: StreamReusableView {
    
    weak var dateLabel: UILabel!
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let dateLabel = Label()
        dateLabel.textColor = Color.grayDark
        dateLabel.textAlignment = .Left
        dateLabel.font = UIFont.fontNormal()
        addSubview(dateLabel)
        self.dateLabel = dateLabel
        dateLabel.snp_makeConstraints(closure: {
            $0.centerY.equalTo(self)
            $0.leading.equalTo(self).offset(12)
            $0.trailing.greaterThanOrEqualTo(self).offset(12)
        })
    }
    
    override func setup(entry: AnyObject) {
        if let item = entry as? HistoryItem {
            dateLabel.text = item.date.stringWithFormat("EEE MMM d, yyyy")
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
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let streamView = StreamView()
        streamView.showsHorizontalScrollIndicator = false
        streamView.showsVerticalScrollIndicator = false
        addSubview(streamView)
        self.streamView = streamView
        streamView.snp_makeConstraints(closure: { $0.edges.equalTo(self) })
    }
    
    internal override func willEnqueue() {
        super.willEnqueue()
        (entry as? HistoryItem)?.offset = streamView.contentOffset
    }
    
    override func loadedWithMetrics(metrics: StreamMetrics) {
        super.loadedWithMetrics(metrics)
        streamView.layout = SquareLayout(horizontal: true)
        dataSource = HistoryItemDataSource(streamView: streamView)
        candyMetrics = dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<CandyCell>()))
        candyMetrics.selection = metrics.selection
        dataSource.layoutSpacing = Constants.pixelSize
        candyMetrics.prepareAppearing = { [weak self] item, _ in
            item.view?.transform = self?.streamView.transform ?? CGAffineTransformIdentity
        }
    }
    
    override func setup(entry: AnyObject) {
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
    @IBOutlet weak var nameLabel: Label!
    @IBOutlet weak var titleLabel: Label!
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let imageView = ImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.cornerRadius = 24
        imageView.defaultBackgroundColor = Color.grayLighter
        imageView.defaultIconColor = UIColor.whiteColor()
        imageView.defaultIconText = "&"
        addSubview(imageView)
        self.imageView = imageView
        
        let nameLabel = Label()
        nameLabel.textColor = Color.grayDarker
        nameLabel.font = UIFont.lightFontSmall()
        nameLabel.preset = FontPreset.Small.rawValue
        addSubview(nameLabel)
        self.nameLabel = nameLabel
        
        let titleLabel = Label()
        titleLabel.textColor = Color.grayLighter
        titleLabel.font = UIFont.lightFontSmaller()
        titleLabel.preset = FontPreset.Smaller.rawValue
        addSubview(titleLabel)
        self.titleLabel = titleLabel
        
        let liveBadge = Label()
        liveBadge.textAlignment = .Center
        liveBadge.cornerRadius = 8
        liveBadge.clipsToBounds = true
        liveBadge.backgroundColor = Color.dangerRed
        liveBadge.textColor = UIColor.whiteColor()
        liveBadge.font = UIFont.lightFontXSmall()
        liveBadge.preset = FontPreset.XSmall.rawValue
        liveBadge.text = "LIVE"
        addSubview(liveBadge)
        
        imageView.snp_makeConstraints(closure: {
            $0.leading.equalTo(self).offset(12)
            $0.centerY.equalTo(self)
            $0.size.equalTo(CGSizeMake(48, 48))
        })
        
        liveBadge.snp_makeConstraints(closure: {
            $0.bottom.equalTo(imageView.snp_centerY)
            $0.leading.equalTo(imageView.snp_trailing).offset(12)
            $0.size.equalTo(CGSizeMake(40, 20))
        })
        
        nameLabel.snp_makeConstraints(closure: {
            $0.leading.equalTo(liveBadge.snp_trailing).offset(8)
            $0.trailing.greaterThanOrEqualTo(self).offset(12)
            $0.centerY.equalTo(liveBadge)
        })
        
        titleLabel.snp_makeConstraints(closure: {
            $0.top.equalTo(imageView.snp_centerY)
            $0.leading.equalTo(imageView.snp_trailing).offset(12)
            $0.trailing.greaterThanOrEqualTo(self).offset(12)
        })
    }
    
    override func setup(entry: AnyObject) {
        if let broadcast = entry as? LiveBroadcast {
            nameLabel.text = "\(broadcast.broadcaster?.name ?? "") \("is_live_streaming".ls)"
            titleLabel?.text = broadcast.displayTitle()
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
            wrap.candies = []
        }
        
        dataSource.wrap = wrap
        dataSource.liveBroadcastMetrics.loader = LayoutStreamLoader<LiveBroadcastMediaView>()
        dataSource.liveBroadcastMetrics.selection = { [weak self] (item, broadcast) -> Void in
            if let broadcast = broadcast as? LiveBroadcast {
                self?.presentLiveBroadcast(broadcast)
            }
        }
        let dateMetrics = dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<HistoryDateSeparator>()))
        dateMetrics.size = 42
        dateMetrics.selection = { [weak self] (item, entry) -> Void in
            if let controller = self?.storyboard?["historyItem"] as? HistoryItemViewController {
                controller.item = entry as? HistoryItem
                self?.navigationController?.pushViewController(controller, animated: false)
            }
        }
        
        candyMetrics = dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<HistoryItemCell>()))
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
        
        if wrap.candies.count > 0 {
            dataSource.paginatedSet?.newer(nil, failure: nil)
            dropDownCollectionView()
        }
        Wrap.notifier().addReceiver(self)
    }
    
    func presentLiveBroadcast(broadcast: LiveBroadcast) {
        if !Network.sharedNetwork.reachable {
            Toast.show("no_internet_connection".ls)
            return
        }
        if let controller = storyboard?["liveViewer"] as? LiveViewerViewController {
            controller.wrap = wrap
            controller.broadcast = broadcast
            navigationController?.pushViewController(controller, animated: false)
        }
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
        streamView.scrollRectToVisible(streamHistoryItem.frame, animated: false)
        guard let cell = streamHistoryItem.view as? HistoryItemCell else { return nil }
        guard let streamCandyItem = cell.streamView.itemPassingTest({ ($0.entry as? Candy) == candy}) else { return nil }
        cell.streamView.scrollRectToVisible(streamCandyItem.frame, animated: false)
        return streamCandyItem.view
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let wrap = wrap where wrap.valid else {
            Dispatch.mainQueue.after(0.5, block: { self.navigationController?.popViewControllerAnimated(false) })
            return
        }
        
        for candy in wrap.candies where candy.valid {
            candy.markAsUnread(false)
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
        guard let wrap = wrap else { return }
        
        let openLiveBroadcast: (Void -> Void) = { [weak self] () -> Void in
            FollowingViewController.followWrapIfNeeded(wrap) {
                Storyboard.LiveBroadcaster.instantiate({ (controller) -> Void in
                    controller.wrap = wrap
                    self?.navigationController?.pushViewController(controller, animated: false)
                })
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
