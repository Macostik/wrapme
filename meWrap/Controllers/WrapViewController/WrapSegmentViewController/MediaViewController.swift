//
//  MediaViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class HistoryItemCell: EntryStreamReusableView<HistoryItem> {
    
    class HistoryItemDataSource: StreamDataSource<[Candy]> {
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
    
    let streamView = StreamView()
    
    private let dateLabel = Label(preset: .Small, weight: .Regular, textColor: Color.orange)
    
    private var dataSource: HistoryItemDataSource!
    
    private var candyMetrics: StreamMetrics<CandyCell>!
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        
        streamView.layout = HorizontalSquareLayout()
        dataSource = HistoryItemDataSource(streamView: streamView)
        candyMetrics = dataSource.addMetrics(StreamMetrics<CandyCell>())
        dataSource.layoutSpacing = Constants.pixelSize
        candyMetrics.prepareAppearing = { [weak self] item, _ in
            item.view?.transform = self?.streamView.transform ?? CGAffineTransformIdentity
        }
        
        streamView.showsHorizontalScrollIndicator = false
        streamView.showsVerticalScrollIndicator = false
        streamView.alwaysBounceHorizontal = true
        streamView.delaysContentTouches = false
        addSubview(streamView)
        
        let dateView = Button()
        dateView.exclusiveTouch = true
        dateView.normalColor = UIColor.whiteColor()
        dateView.highlightedColor = Color.grayLightest
        dateView.backgroundColor = UIColor.whiteColor()
        dateView.addTarget(self, action: #selector(HistoryItemCell.openHistoryItem(_:)), forControlEvents: .TouchUpInside)
        addSubview(dateView)
        
        dateLabel.textAlignment = .Left
        dateView.addSubview(dateLabel)
        
        let arrow = Label(icon: "x", size: 15, textColor: Color.orange)
        arrow.textAlignment = .Left
        dateView.addSubview(arrow)
        
        streamView.snp_makeConstraints(closure: {
            $0.top.equalTo(self).offset(28)
            $0.leading.trailing.bottom.equalTo(self)
        })
        
        dateView.snp_makeConstraints(closure: {
            $0.leading.top.trailing.equalTo(self)
            $0.height.equalTo(28)
        })
        
        dateLabel.snp_makeConstraints(closure: {
            $0.leading.equalTo(dateView).offset(8)
            $0.trailing.equalTo(arrow.snp_leading)
            $0.centerY.equalTo(dateView)
        })
        
        arrow.snp_makeConstraints(closure: {
            $0.centerY.equalTo(dateLabel)
        })
    }
    
    internal override func willEnqueue() {
        super.willEnqueue()
        entry?.offset = streamView.contentOffset
    }
    
    override func setup(item: HistoryItem) {
        streamView.layoutIfNeeded()
        dateLabel.text = item.date.stringWithFormat("EEE MMM d, yyyy")
        let candies = item.entries
        if item.date.isToday() && candies.count >= 3 {
            streamView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
            dataSource.items = candies.reverse()
        } else {
            streamView.transform = CGAffineTransformIdentity
            dataSource.items = candies
        }
        streamView.contentOffset.x = smoothstep(0, streamView.maximumContentOffset.x, item.offset.x)
    }
    
    func openHistoryItem(sender: Button) {
        metrics?.select(self)
    }
}

class LiveBroadcastMediaView: EntryStreamReusableView<LiveBroadcast> {
    
    private let imageView = ImageView(backgroundColor: UIColor.whiteColor())
    private let nameLabel = Label(preset: .Small)
    private let titleLabel = Label(preset: .Smaller, textColor: Color.grayLighter)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        imageView.cornerRadius = 24
        imageView.defaultBackgroundColor = Color.grayLighter
        imageView.defaultIconColor = UIColor.whiteColor()
        imageView.defaultIconText = "&"
        addSubview(imageView)
        addSubview(nameLabel)
        addSubview(titleLabel)
        
        let liveBadge = Label(preset: .XSmall, textColor: UIColor.whiteColor())
        liveBadge.textAlignment = .Center
        liveBadge.cornerRadius = 8
        liveBadge.clipsToBounds = true
        liveBadge.backgroundColor = Color.dangerRed
        liveBadge.text = "LIVE"
        addSubview(liveBadge)
        
        imageView.snp_makeConstraints(closure: {
            $0.leading.equalTo(self).offset(12)
            $0.centerY.equalTo(self)
            $0.size.equalTo(48)
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
            $0.trailing.equalTo(self).inset(12)
        })
    }
    
    override func setup(broadcast: LiveBroadcast) {
        nameLabel.text = "\(broadcast.broadcaster?.name ?? "") \("is_live_streaming".ls)"
        titleLabel.text = broadcast.displayTitle()
        imageView.url = broadcast.broadcaster?.avatar?.small
    }
}

protocol MediaViewControllerDelegate {
    func mediaViewControllerDidAddPhoto(controller: MediaViewController)
}

class MediaViewController: WrapSegmentViewController {
    
    lazy var dataSource: MediaDataSource = MediaDataSource(streamView: self.streamView)
    @IBOutlet  weak var streamView: StreamView!
    @IBOutlet var primaryConstraint: LayoutPrioritizer!
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var liveButton: UIButton?
    
    var history: History!
    
    weak var candyMetrics: StreamMetrics<HistoryItemCell>!
    @IBOutlet weak var scrollDirectionPrioritizer: LayoutPrioritizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let wrap = wrap else {
            return
        }
        
        streamView.contentInset = streamView.scrollIndicatorInsets
        
        dataSource.scrollDirectionLayoutPrioritizer = self.scrollDirectionPrioritizer
        dataSource.numberOfGridColumns = 3
        dataSource.layoutSpacing = Constants.pixelSize
        dataSource.placeholderMetrics = PlaceholderView.mediaPlaceholderMetrics()
        
        if wrap.requiresFollowing && Network.sharedNetwork.reachable {
            wrap.candies = []
        }
        
        dataSource.wrap = wrap
        dataSource.liveBroadcastMetrics.selection = { [weak self] view -> Void in
            if let broadcast = view.entry {
                self?.presentLiveBroadcast(broadcast)
            }
        }
        
        candyMetrics = dataSource.addMetrics(StreamMetrics<HistoryItemCell>())
        candyMetrics.prepareAppearing = { [weak self] item, view in
            view.candyMetrics.selection = { view -> Void in
                CandyEnlargingPresenter.handleCandySelection(view, historyItem: self?.history.itemWithCandy(view.entry), dismissingView: { candy -> UIView? in
                    return self?.enlargingPresenterDismissingView(candy)
                })
            }
        }
        candyMetrics.size = round(view.width / 2.5) + 28
        candyMetrics.selectable = false
        candyMetrics.selection = { [weak self] view -> Void in
            let controller = Storyboard.HistoryItem.instantiate()
            controller.item = view.entry
            self?.navigationController?.pushViewController(controller, animated: false)
        }
        
        dataSource.appendableBlock = { [weak self] (dataSource) -> Bool in
            if let wrap = self?.wrap {
                return wrap.uploaded
            } else {
                return false
            }
        }
        
        history = History(wrap: wrap)
        
        let refresher = Refresher(scrollView: streamView)
        refresher.style = .Orange
        refresher.addTarget(dataSource, action: #selector(dataSource.refresh(_:)), forControlEvents: .ValueChanged)
        refresher.addTarget(self, action: #selector(self.refreshUserActivities), forControlEvents: .ValueChanged)
                
        Network.sharedNetwork.addReceiver(self)
        
        if wrap.candies.count > 0 {
            dataSource.items?.newer(nil, failure: nil)
            dropDownCollectionView()
        }
        Wrap.notifier().addReceiver(self)
    }
    
    func refreshUserActivities() {
        if let wrap = wrap {
            NotificationCenter.defaultCenter.refreshWrapUserActivities(wrap, completionHandler: { [weak self] () -> Void in
                self?.dataSource.reload()
            })
        }
    }
    
    func presentLiveBroadcast(broadcast: LiveBroadcast) {
        if !Network.sharedNetwork.reachable {
            InfoToast.show("no_internet_connection".ls)
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
        liveButton?.alpha = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo).denied ? 0.5 : 1
    }
    
    func enlargingPresenterDismissingView(candy: Candy) -> UIView? {
        guard let historyItem = history.entries[{ $0.entries.contains(candy) }] else { return nil }
        guard let streamHistoryItem = streamView.itemPassingTest({ $0.entry === historyItem && $0.metrics === candyMetrics}) else { return nil }
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
        
        dataSource.items = history
        if view.width > view.height {
            Dispatch.mainQueue.async { [weak self] _ in
                self?.dataSource.reload()
            }
        }
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
                (controller.delegate as? MediaViewControllerDelegate)?.mediaViewControllerDidAddPhoto(controller)
            }
        }
    }
    
    @IBAction func liveBroadcast(sender: UIButton) {
        if !Network.sharedNetwork.reachable {
            InfoToast.show("no_internet_connection".ls)
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
        
        AVCaptureDevice.authorize({ _ in
            openLiveBroadcast()
            sender.alpha = 1
            }) { _ in
                sender.alpha =  0.5
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
