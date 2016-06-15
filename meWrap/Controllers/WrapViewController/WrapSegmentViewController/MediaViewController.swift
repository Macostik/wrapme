//
//  MediaViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation

class HistoryItemHeader: EntryStreamReusableView<HistoryItem> {
    
    private let dateLabel = Label(preset: .Small, weight: .Regular, textColor: Color.orange)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        
        let dateView = Button()
        dateView.exclusiveTouch = true
        dateView.normalColor = UIColor.whiteColor()
        dateView.highlightedColor = Color.grayLightest
        dateView.backgroundColor = UIColor.whiteColor()
        dateView.addTarget(self, action: #selector(self.openHistoryItem(_:)), forControlEvents: .TouchUpInside)
        addSubview(dateView)
        
        dateLabel.textAlignment = .Left
        dateView.addSubview(dateLabel)
        
        let arrow = Label(icon: "x", size: 15, textColor: Color.orange)
        arrow.textAlignment = .Left
        dateView.addSubview(arrow)
        
        dateView.snp_makeConstraints(closure: {
            $0.edges.equalTo(self)
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
    
    override func setup(item: HistoryItem) {
        dateLabel.text = item.date.stringWithFormat("EEE MMM d, yyyy")
    }
    
    func openHistoryItem(sender: Button) {
        metrics?.select(self)
    }
}

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
    
    private var dataSource: HistoryItemDataSource!
    
    private var candyMetrics: StreamMetrics<CandyCell>!
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        
        let layout = HorizontalSquareLayout()
        layout.spacing = 1
        streamView.layout = layout
        dataSource = HistoryItemDataSource(streamView: streamView)
        candyMetrics = dataSource.addMetrics(StreamMetrics<CandyCell>())
        candyMetrics.prepareAppearing = { [weak self] item, _ in
            item.view?.transform = self?.streamView.transform ?? CGAffineTransformIdentity
        }
        
        streamView.showsHorizontalScrollIndicator = false
        streamView.showsVerticalScrollIndicator = false
        streamView.alwaysBounceHorizontal = true
        streamView.delaysContentTouches = false
        add(streamView) {
            $0.edges.equalTo(self)
        }
    }
    
    internal override func willEnqueue() {
        super.willEnqueue()
        entry?.offset = streamView.contentOffset
    }
    
    override func setup(item: HistoryItem) {
        streamView.layoutIfNeeded()
        let candies = item.entries
        if item.date.isToday() && candies.count >= 3 {
            streamView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
            dataSource.items = candies
        } else {
            streamView.transform = CGAffineTransformIdentity
            dataSource.items = candies.reverse()
        }
        streamView.contentOffset.x = smoothstep(0, streamView.maximumContentOffset.x, item.offset.x)
    }
}

final class LiveBroadcastMediaView: EntryStreamReusableView<LiveBroadcast> {
    
    private let imageView = ImageView(backgroundColor: UIColor.whiteColor(), placeholder: ImageView.Placeholder.gray)
    private let nameLabel = Label(preset: .Small)
    private let titleLabel = Label(preset: .Smaller, textColor: Color.grayLighter)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        imageView.cornerRadius = 24
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

class MediaViewController: WrapSegmentViewController {
    
    var isMediaLayout = true {
        didSet {
            guard isMediaLayout != oldValue else { return }
            applyLayout(isMediaLayout, reload: true)
        }
    }
    
    private func applyLayout(isMediaLayout: Bool, reload: Bool) {
        if isMediaLayout {
            dataSource = mediaDataSource
            streamView.layout = StreamLayout()
        } else {
            dataSource = mosaicDataSource
            let layout = MosaicLayout()
            layout.spacing = 1
            streamView.layout = layout
        }
        dataSource.streamView = streamView
        streamView.delegate = dataSource
        streamView.dataSource = dataSource
        layoutButton.selected = isMediaLayout
        if reload {
            dataSource.items = history
        }
    }
    
    lazy var dataSource: PaginatedStreamDataSource<History> = self.mediaDataSource
    lazy var mediaDataSource: PaginatedStreamDataSource<History> = self.createMediaDataSource()
    lazy var mosaicDataSource: PaginatedStreamDataSource<History> = self.createMosaicDataSource()
    private let streamView = StreamView()
    let addPhotoButton = Button(type: .Custom)
    private let liveButton = Button(preset: .Normal, weight: .Regular, textColor: UIColor.whiteColor())
    private let layoutButton = Button(icon: "O", size: 24, textColor: UIColor.whiteColor())
    
    var history: History!
    
    override func loadView() {
        super.loadView()
        streamView.delaysContentTouches = false
        streamView.alwaysBounceVertical = true
        view.add(streamView) { (make) in
            make.edges.equalTo(view)
        }
        liveButton.cornerRadius = 28
        liveButton.setTitle("LIVE", forState: .Normal)
        liveButton.clipsToBounds = true
        liveButton.normalColor = Color.orange.colorWithAlphaComponent(0.78)
        liveButton.backgroundColor = liveButton.normalColor
        liveButton.highlightedColor = Color.orangeDark
        liveButton.setTitleColor(Color.grayLightest, forState: .Highlighted)
        liveButton.addTarget(self, touchUpInside: #selector(self.liveBroadcast(_:)))
        liveButton.exclusiveTouch = true
        view.addSubview(liveButton)
        addPhotoButton.setBackgroundImage(UIImage(named: "btn_wrap_camera_enabled"), forState: .Normal)
        addPhotoButton.setBackgroundImage(UIImage(named: "btn_wrap_camera_pressed"), forState: .Highlighted)
        addPhotoButton.exclusiveTouch = true
        view.addSubview(addPhotoButton)
        layoutButton.cornerRadius = 28
        layoutButton.setTitle("S", forState: .Selected)
        layoutButton.clipsToBounds = true
        layoutButton.normalColor = Color.orange.colorWithAlphaComponent(0.78)
        layoutButton.backgroundColor = layoutButton.normalColor
        layoutButton.highlightedColor = Color.orangeDark
        layoutButton.setTitleColor(Color.grayLightest, forState: .Highlighted)
        layoutButton.addTarget(self, touchUpInside: #selector(self.changeLayout(_:)))
        layoutButton.exclusiveTouch = true
        view.addSubview(layoutButton)
        
        defaultButtonsLayout()
        
        streamView.trackScrollDirection = true
        streamView.didScrollUp = { [weak self] _ in
            self?.didScrollUp()
        }
        streamView.didScrollDown = { [weak self] _ in
            self?.didScrollDown()
        }
        
        let didEndDecelerating: () -> () = { [weak self] _ in
            self?.streamView.direction = .Down
        }
        mediaDataSource.didEndDecelerating = didEndDecelerating
        mosaicDataSource.didEndDecelerating = didEndDecelerating
    }
    
    private func didScrollUp() {
        liveButton.snp_remakeConstraints { (make) in
            make.size.equalTo(56)
            make.leading.equalTo(view.snp_trailing).offset(8)
            make.bottom.equalTo(view).offset(-4)
        }
        addPhotoButton.snp_remakeConstraints { (make) in
            make.size.equalTo(84)
            make.top.equalTo(view.snp_bottom).offset(4)
            make.centerX.equalTo(view)
        }
        layoutButton.snp_remakeConstraints { (make) in
            make.size.equalTo(56)
            make.trailing.equalTo(view.snp_leading).offset(-8)
            make.bottom.equalTo(view).offset(-4)
        }
        animate { 
            view.layoutIfNeeded()
        }
    }
    
    private func defaultButtonsLayout() {
        liveButton.snp_remakeConstraints { (make) in
            make.size.equalTo(56)
            make.trailing.equalTo(view).offset(-8)
            make.bottom.equalTo(view).offset(-4)
        }
        addPhotoButton.snp_remakeConstraints { (make) in
            make.size.equalTo(84)
            make.bottom.equalTo(view).offset(-4)
            make.centerX.equalTo(view)
        }
        layoutButton.snp_remakeConstraints { (make) in
            make.size.equalTo(56)
            make.leading.equalTo(view).offset(8)
            make.bottom.equalTo(view).offset(-4)
        }
    }
    
    private func didScrollDown() {
        defaultButtonsLayout()
        animate {
            view.layoutIfNeeded()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let wrap = wrap else { return }
        
        streamView.contentInset = streamView.scrollIndicatorInsets

        streamView.placeholderMetrics = PlaceholderView.mediaPlaceholderMetrics()
        
        history = History(wrap: wrap)
        
        let refresher = Refresher(scrollView: streamView)
        refresher.style = .Orange
        refresher.addTarget(dataSource, action: #selector(dataSource.refresh(_:)), forControlEvents: .ValueChanged)
        refresher.addTarget(self, action: #selector(self.refreshUserActivities), forControlEvents: .ValueChanged)
                
        Network.network.subscribe(self) { [unowned self] _ in
            self.dataSource.reload()
        }
        
        if wrap.candies.count > 0 {
            dataSource.items?.newer(nil, failure: nil)
        }
        Wrap.notifier().addReceiver(self)
    }
    
    func createMediaDataSource() -> PaginatedStreamDataSource<History> {
        let dataSource = MediaDataSource()
        dataSource.wrap = wrap
        dataSource.liveBroadcastMetrics.selection = { [weak self] view -> Void in
            if let broadcast = view.entry {
                self?.presentLiveBroadcast(broadcast)
            }
        }
        
        let headerMetrics = specify(StreamMetrics<HistoryItemHeader>(size: 28)) {
            $0.isSeparator = true
            $0.selection = { [weak self] view -> Void in
                let controller = HistoryItemViewController()
                controller.item = view.entry
                self?.navigationController?.pushViewController(controller, animated: false)
            }
        }
        
        dataSource.addMetrics(headerMetrics)
        
        let candyMetrics = dataSource.addMetrics(StreamMetrics<HistoryItemCell>())
        candyMetrics.prepareAppearing = { [weak self] item, view in
            view.candyMetrics.selection = { view -> Void in
                CandyPresenter.present(view, history: self?.history, dismissingView: { candy -> UIView? in
                    return self?.dismissingView(candy)
                })
            }
        }
        candyMetrics.size = round(view.width / 2.5)
        candyMetrics.selectable = false
        
        dataSource.appendableBlock = { [weak self] (dataSource) -> Bool in
            if let wrap = self?.wrap {
                return wrap.uploaded
            } else {
                return false
            }
        }
        return dataSource
    }
    
    func createMosaicDataSource() -> PaginatedStreamDataSource<History> {
        let dataSource = MosaicMediaDataSource()
        dataSource.liveBroadcastMetrics.selection = { [weak self] view -> Void in
            if let broadcast = view.entry {
                self?.presentLiveBroadcast(broadcast)
            }
        }
        dataSource.wrap = wrap
        let headerMetrics = specify(StreamMetrics<HistoryItemHeader>(size: 28)) {
            $0.isSeparator = true
            $0.selection = { [weak self] view -> Void in
                let controller = HistoryItemViewController()
                controller.item = view.entry
                self?.navigationController?.pushViewController(controller, animated: false)
            }
            $0.finalizeAppearing = { [weak self] item, view in
                view.entry = self?.history.entries[safe: item.position.section - 1]
            }
            $0.modifyItem = { item in
                item.hidden = item.position.section == 0
            }
        }
        dataSource.addSectionHeaderMetrics(headerMetrics)
        dataSource.addMetrics(StreamMetrics<CandyCell>()).selection = { [weak self] view -> Void in
            CandyPresenter.present(view, history: self?.history, dismissingView: { candy -> UIView? in
                return self?.dismissingView(candy)
            })
        }
        dataSource.appendableBlock = { [weak self] (dataSource) -> Bool in
            if let wrap = self?.wrap {
                return wrap.uploaded
            } else {
                return false
            }
        }
        return dataSource
    }
    
    func refreshUserActivities() {
        if let wrap = wrap {
            NotificationCenter.defaultCenter.refreshWrapUserActivities(wrap, completionHandler: { [weak self] () -> Void in
                self?.dataSource.reload()
            })
        }
    }
    
    func presentLiveBroadcast(broadcast: LiveBroadcast) {
        if !Network.network.reachable {
            Toast.show("no_internet_connection".ls)
            return
        }
        let controller = LiveViewerViewController()
        controller.wrap = wrap
        controller.broadcast = broadcast
        navigationController?.pushViewController(controller, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        liveButton.alpha = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo).denied ? 0.5 : 1
    }
    
    func dismissingView(candy: Candy) -> UIView? {
        if isMediaLayout {
            guard let historyItem = history.entries[{ $0.entries.contains(candy) }] else { return nil }
            guard let streamHistoryItem = streamView.itemPassingTest({ $0.entry === historyItem && $0.metrics is StreamMetrics<HistoryItemCell>}) else { return nil }
            streamView.scrollRectToVisible(streamHistoryItem.frame, animated: false)
            guard let cell = streamHistoryItem.view as? HistoryItemCell else { return nil }
            guard let streamCandyItem = cell.streamView.itemPassingTest({ ($0.entry as? Candy) == candy}) else { return nil }
            cell.streamView.scrollRectToVisible(streamCandyItem.frame, animated: false)
            return streamCandyItem.view
        } else {
            guard let item = streamView.itemPassingTest({ $0.entry === candy }) else { return nil }
            streamView.scrollRectToVisible(item.frame, animated: false)
            return item.view
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let wrap = wrap where wrap.valid else {
            Dispatch.mainQueue.after(0.5, block: { self.navigationController?.popViewControllerAnimated(false) })
            return
        }
        applyLayout(isMediaLayout, reload: false)
        dataSource.items = history
    }
    
    @IBAction func changeLayout(sender: UIButton) {
        isMediaLayout = !isMediaLayout
    }
    
    @IBAction func liveBroadcast(sender: UIButton) {
        if !Network.network.reachable {
            Toast.show("no_internet_connection".ls)
            return
        }
        guard let wrap = wrap else { return }
        
        let openLiveBroadcast: (Void -> Void) = { [weak self] () -> Void in
            let controller = LiveBroadcasterViewController()
            controller.wrap = wrap
            self?.navigationController?.pushViewController(controller, animated: false)
        }
        
        AVCaptureDevice.authorize({ _ in
            openLiveBroadcast()
            sender.alpha = 1
            }) { _ in
                sender.alpha =  0.5
        }
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
