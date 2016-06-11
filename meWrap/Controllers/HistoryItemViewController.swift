//
//  HistoryItemViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

final class HistoryItemCoverView: EntryStreamReusableView<Candy> {
    
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        addSubview(imageView)
        imageView.snp_makeConstraints { $0.edges.equalTo(self) }
    }
    
    override func setup(candy: Candy) {
        imageView.url = candy.asset?.medium
    }
}

final class HistoryItemViewController: BaseViewController {
    
    private let nameLabel = Label(preset: .Normal, textColor: UIColor.whiteColor())
    
    private let dateLabel = Label(preset: .Smaller, textColor: UIColor.whiteColor())
    
    private let cover = ImageView(backgroundColor: UIColor.blackColor())
    
    private var candies: [Candy]?
    
    var item: HistoryItem?
    
    private let streamView = StreamView()
    
    private lazy var dataSource: StreamDataSource<[Candy]> = StreamDataSource(streamView: self.streamView)
    
    let coverView = UIView()
    
    override func loadView() {
        super.loadView()
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = UIColor.whiteColor()
        
        let infoView = UIView()
        coverView.backgroundColor = UIColor.blackColor()
        infoView.backgroundColor = Color.orange.colorWithAlphaComponent(0.5)
        
        view.add(streamView) { (make) in
            make.edges.equalTo(view)
        }
        
        let anchorView = streamView.add(UIView()) { (make) -> Void in
            make.centerX.top.equalTo(streamView)
            make.width.equalTo(streamView)
            make.height.equalTo(streamView.snp_width).multipliedBy(0.6)
        }
        
        streamView.add(coverView) { (make) -> Void in
            make.centerX.equalTo(streamView)
            make.bottom.equalTo(anchorView)
            make.width.equalTo(streamView)
            make.height.equalTo(streamView.snp_width).multipliedBy(0.6)
        }
        
        coverView.add(cover) { (make) -> Void in
            make.edges.equalTo(coverView)
        }
        coverView.add(infoView) { (make) -> Void in
            make.leading.trailing.bottom.equalTo(coverView)
        }
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        coverView.insertSubview(blurView, belowSubview: infoView)
        blurView.snp_makeConstraints { (make) in
            make.edges.equalTo(infoView)
        }
        cover.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Vertical)
        cover.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Vertical)
        infoView.add(nameLabel) { (make) -> Void in
            make.leading.top.equalTo(infoView).offset(12)
            make.trailing.lessThanOrEqualTo(infoView).offset(-12)
            make.bottom.equalTo(infoView.snp_centerY)
        }
        infoView.add(dateLabel) { (make) -> Void in
            make.leading.bottom.equalTo(infoView).inset(12)
            make.trailing.lessThanOrEqualTo(infoView).offset(-12)
            make.top.equalTo(infoView.snp_centerY)
        }
        
        view.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(view).offset(12)
            make.centerY.equalTo(view.snp_top).offset(42)
        }
    }
    
    deinit {
        streamView.layer.removeObserver(self, forKeyPath: "bounds", context: nil)
    }
    
    override func viewDidLoad() {
        nameLabel.text = item?.history.wrap?.name
        dateLabel.text = item?.date.stringWithFormat("EEE MMM d, yyyy")
        
        super.viewDidLoad()
        
        let layout = GridLayout()
        layout.numberOfColumns = 3
        layout.spacing = 1
        layout.offset = cover.height + 1
        streamView.layout = layout
        streamView.placeholderMetrics = PlaceholderView.singleDayPlaceholderMetrics()
        streamView.placeholderMetrics?.isSeparator = true
        
        let metrics = dataSource.addMetrics(StreamMetrics<CandyCell>())
        metrics.modifyItem = { (item) in
            item.ratio = (item.entry as? Candy)?.ratio ?? 1
        }
        metrics.selection = { [weak self] view -> Void in
            self?.streamView.lock()
            CandyEnlargingPresenter.handleCandySelection(view, historyItem: self?.item, dismissingView: { candy -> UIView? in
                guard let streamCandyItem = self?.streamView.itemPassingTest({ ($0.entry as? Candy) == candy}) else { return nil }
                self?.streamView.scrollRectToVisible(streamCandyItem.frame, animated: false)
                return streamCandyItem.view
            })
        }
        dataSource.items = item?.entries
        item?.history.didChangeNotifier.subscribe(self, block: { [unowned self] (value) in
            guard let item = self.item else { return }
            self.dataSource.items = item.entries
            if let candy = self.coverCandy where !item.entries.contains(candy) {
                self.coverCandy = item.entries.first
            }
            if item.entries.count == 0 {
                for _item in item.history.entries where _item.date.isSameDay(item.date) {
                    self.item = _item
                    self.dataSource.items = _item.entries
                }
            }
        })
        
        recursivelyUpdateCover(false)
        
        streamView.layer.addObserver(self, forKeyPath: "bounds", options: .New, context: nil)
        
        view.addGestureRecognizer(streamView.panGestureRecognizer)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let offset = min(streamView.layer.bounds.origin.y, 0)
        coverView.snp_updateConstraints(closure: { (make) in
            make.height.equalTo(view.snp_width).multipliedBy(0.6).offset(-offset)
        })
    }
    
    private var coverCandy: Candy?
    
    private func setCoverCandy(candy: Candy?, animated: Bool) {
        coverCandy = candy
        if animated {
            UIView.animateWithDuration(0.5, animations: {
                self.cover.alpha = 0
                }, completion: { (_) in
                    self.cover.url = candy?.asset?.medium
                    UIView.animateWithDuration(0.5, animations: {
                        self.cover.alpha = 1
                        })
            })
        } else {
            cover.url = candy?.asset?.medium
        }
    }
    
    private func recursivelyUpdateCover(animated: Bool) {
        candies = item?.entries
        if let currentCandy = coverCandy, let index = item?.entries.indexOf(currentCandy) {
            let candy = item?.entries[safe: index + 1] ?? item?.entries.first
            setCoverCandy(candy, animated: animated)
        } else {
            setCoverCandy(item?.entries.first, animated: animated)
        }
        Dispatch.mainQueue.after(4) { [weak self] _ in self?.recursivelyUpdateCover(true) }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.unlock()
        streamView.reload()
    }
}
