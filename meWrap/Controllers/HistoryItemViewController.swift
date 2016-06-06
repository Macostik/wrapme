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
    
    private let coverStreamView = StreamView()
    
    private lazy var coverDataSource: StreamDataSource<[Candy]> = StreamDataSource(streamView: self.coverStreamView)
    
    var item: HistoryItem?
    
    private let streamView = StreamView()
    
    private lazy var dataSource: StreamDataSource<[Candy]> = StreamDataSource(streamView: self.streamView)
    
    override func loadView() {
        super.loadView()
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = UIColor.whiteColor()
        view.add(streamView) { (make) in
            make.edges.equalTo(view)
        }
        
        let coverView = UIView()
        let infoView = UIView()
        coverView.backgroundColor = UIColor.blackColor()
        infoView.backgroundColor = Color.orange
        streamView.addSubview(coverView)
        coverView.addSubview(infoView)
        coverView.addSubview(coverStreamView)
        infoView.addSubview(nameLabel)
        infoView.addSubview(dateLabel)
        
        coverView.snp_makeConstraints { (make) -> Void in
            make.width.top.centerX.equalTo(streamView)
            make.height.equalTo(view.width * 0.6)
        }
        
        coverStreamView.snp_makeConstraints { (make) -> Void in
            make.trailing.leading.top.equalTo(coverView)
            make.bottom.equalTo(infoView.snp_top)
        }
        
        infoView.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.bottom.equalTo(coverView)
        }
        
        nameLabel.snp_makeConstraints { (make) -> Void in
            make.leading.top.equalTo(infoView).offset(12)
            make.trailing.greaterThanOrEqualTo(infoView).inset(12)
            make.bottom.equalTo(infoView.snp_centerY)
        }
        
        dateLabel.snp_makeConstraints { (make) -> Void in
            make.leading.bottom.equalTo(infoView).inset(12)
            make.trailing.greaterThanOrEqualTo(infoView).inset(12)
            make.top.equalTo(infoView.snp_centerY)
        }
        
        view.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(view).offset(12)
            make.centerY.equalTo(view.snp_top).offset(42)
        }
    }
    
    override func viewDidLoad() {
        nameLabel.text = item?.history.wrap?.name
        dateLabel.text = item?.date.stringWithFormat("EEE MMM d, yyyy")
        
        super.viewDidLoad()
        
        coverStreamView.userInteractionEnabled = false
        coverStreamView.layout = HorizontalStreamLayout()
        coverDataSource.addMetrics(StreamMetrics<HistoryItemCoverView>(size: view.width))
        
        streamView.layout = SquareGridLayout()
        dataSource.offsetForGridColumns = view.width * 0.6
        dataSource.placeholderMetrics = PlaceholderView.singleDayPlaceholderMetrics()
        dataSource.placeholderMetrics?.isSeparator = true
        dataSource.numberOfGridColumns = 3
        dataSource.layoutSpacing = Constants.pixelSize
        
        let metrics = dataSource.addMetrics(StreamMetrics<CandyCell>())
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
    }
    
    private var coverCandy: Candy?
    
    private func setCoverCandy(candy: Candy?, animated: Bool) {
        coverCandy = candy
        coverStreamView.scrollToItemPassingTest({ $0.entry === candy }, animated: animated)
    }
    
    private func recursivelyUpdateCover(animated: Bool) {
        coverDataSource.items = item?.entries
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
