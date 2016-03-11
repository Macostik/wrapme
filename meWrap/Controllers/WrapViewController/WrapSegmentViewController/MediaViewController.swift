//
//  MediaViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

protocol HistoryItemCellDelegate: class {
    func historyItemCell(cell: HistoryItemCell, didSelectItem item: HistoryItem)
}

class HistoryItemCell: StreamReusableView {
    
    weak var delegate: HistoryItemCellDelegate?
    
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
    
    weak var streamView: StreamView!
    
    weak var dateLabel: UILabel!
    
    private var dataSource: HistoryItemDataSource!
    
    private var candyMetrics: StreamMetrics!
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let streamView = StreamView()
        streamView.showsHorizontalScrollIndicator = false
        streamView.showsVerticalScrollIndicator = false
        streamView.alwaysBounceHorizontal = true
        addSubview(streamView)
        self.streamView = streamView
        
        let dateView = Button()
        dateView.exclusiveTouch = true
        dateView.normalColor = UIColor.whiteColor()
        dateView.highlightedColor = Color.orange
        dateView.cornerRadius = 7
        dateView.clipsToBounds = true
        dateView.backgroundColor = UIColor.whiteColor()
        dateView.borderWidth = 1
        dateView.borderColor = Color.orange
        dateView.addTarget(self, action: "openHistoryItem:", forControlEvents: .TouchUpInside)
        addSubview(dateView)
        
        let dateLabel = Label(preset: FontPreset.Normal, weight: UIFontWeightRegular, textColor: Color.orange)
        dateLabel.highlightedTextColor = UIColor.whiteColor()
        dateLabel.textAlignment = .Left
        dateView.addSubview(dateLabel)
        self.dateLabel = dateLabel
        dateView.highlightings.append(dateLabel)
        
        let arrow = Label(icon: "x", size: 15, textColor: Color.orange)
        arrow.highlightedTextColor = UIColor.whiteColor()
        arrow.textAlignment = .Left
        dateView.addSubview(arrow)
        dateView.highlightings.append(arrow)
        
        streamView.snp_makeConstraints(closure: {
            $0.top.equalTo(self).offset(32)
            $0.leading.trailing.bottom.equalTo(self)
        })
        
        dateView.snp_makeConstraints(closure: {
            $0.leading.top.equalTo(self).offset(12)
            $0.height.equalTo(40)
        })
        
        dateLabel.snp_makeConstraints(closure: {
            $0.leading.equalTo(dateView).offset(8)
            $0.trailing.equalTo(arrow.snp_leading)
            $0.top.bottom.equalTo(dateView).inset(6)
        })
        
        arrow.snp_makeConstraints(closure: {
            $0.trailing.equalTo(dateView).inset(8)
            $0.centerY.equalTo(dateLabel)
        })
    }
    
    internal override func willEnqueue() {
        super.willEnqueue()
        (entry as? HistoryItem)?.offset = streamView.contentOffset
    }
    
    override func loadedWithMetrics(metrics: StreamMetrics) {
        super.loadedWithMetrics(metrics)
        streamView.layout = SquareLayout(streamView: streamView, horizontal: true)
        dataSource = HistoryItemDataSource(streamView: streamView)
        candyMetrics = dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<CandyCell>()))
        candyMetrics.selection = metrics.selection
        dataSource.layoutSpacing = Constants.pixelSize
        candyMetrics.prepareAppearing = { [weak self] item, _ in
            item.view?.transform = self?.streamView.transform ?? CGAffineTransformIdentity
        }
    }
    
    override func setup(entry: AnyObject?) {
        streamView.layoutIfNeeded()
        if let item = entry as? HistoryItem {
            dateLabel.text = item.date.stringWithFormat("EEE MMM d, yyyy")
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
    
    func openHistoryItem(sender: Button) {
        if let item = entry as? HistoryItem {
            delegate?.historyItemCell(self, didSelectItem: item)
        }
    }
}

class LiveBroadcastMediaView: StreamReusableView {
    
    @IBOutlet weak var imageView: ImageView!
    @IBOutlet weak var nameLabel: Label!
    @IBOutlet weak var titleLabel: Label!
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let imageView = ImageView(backgroundColor: UIColor.whiteColor())
        imageView.cornerRadius = 24
        imageView.defaultBackgroundColor = Color.grayLighter
        imageView.defaultIconColor = UIColor.whiteColor()
        imageView.defaultIconText = "&"
        addSubview(imageView)
        self.imageView = imageView
        
        let nameLabel = Label(preset: FontPreset.Small, weight: UIFontWeightLight)
        addSubview(nameLabel)
        self.nameLabel = nameLabel
        
        let titleLabel = Label(preset: FontPreset.Smaller, weight: UIFontWeightLight, textColor: Color.grayLighter)
        addSubview(titleLabel)
        self.titleLabel = titleLabel
        
        let liveBadge = Label(preset: FontPreset.XSmall, weight: UIFontWeightLight, textColor: UIColor.whiteColor())
        liveBadge.textAlignment = .Center
        liveBadge.cornerRadius = 8
        liveBadge.clipsToBounds = true
        liveBadge.backgroundColor = Color.dangerRed
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
            $0.trailing.equalTo(self).inset(12)
        })
    }
    
    override func setup(entry: AnyObject?) {
        if let broadcast = entry as? LiveBroadcast {
            nameLabel.text = "\(broadcast.broadcaster?.name ?? "") \("is_live_streaming".ls)"
            titleLabel?.text = broadcast.displayTitle()
            imageView.url = broadcast.broadcaster?.avatar?.small
        }
    }
}

protocol MediaViewControllerDelegate {
    func mediaViewControllerDidAddPhoto(controller: MediaViewController)
}

class MediaViewController: WrapSegmentViewController {
    
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
        dataSource.placeholderMetrics = StreamMetrics(loader: PlaceholderView.mediaPlaceholderLoader())
        
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
        
        candyMetrics = dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<HistoryItemCell>()))
        candyMetrics.prepareAppearing = { item, view in
            (view as? HistoryItemCell)?.delegate = self
        }
        candyMetrics.size = round(view.width / 2.5) + 32
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
        
        let refresher = Refresher(scrollView: streamView)
        refresher.style = .Orange
        refresher.addTarget(dataSource, action: "refresh:", forControlEvents: .ValueChanged)
        refresher.addTarget(self, action: "refreshUserActivities", forControlEvents: .ValueChanged)
        
        uploadingView.uploader = Uploader.candyUploader
        
        Network.sharedNetwork.addReceiver(self)
        
        if wrap.candies.count > 0 {
            dataSource.paginatedSet?.newer(nil, failure: nil)
            dropDownCollectionView()
        }
        Wrap.notifier().addReceiver(self)
    }
    
    func refreshUserActivities() {
        if let wrap = wrap {
            NotificationCenter.defaultCenter.refreshUserActivities(wrap, completionHandler: { [weak self] () -> Void in
                self?.dataSource.reload()
            })
        }
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
                (controller.delegate as? MediaViewControllerDelegate)?.mediaViewControllerDidAddPhoto(controller)
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

extension MediaViewController: HistoryItemCellDelegate {
    
    func historyItemCell(cell: HistoryItemCell, didSelectItem item: HistoryItem) {
        let controller = Storyboard.HistoryItem.instantiate()
        controller.item = item
        navigationController?.pushViewController(controller, animated: false)
    }
}
