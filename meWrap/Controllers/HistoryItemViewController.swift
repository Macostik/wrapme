//
//  HistoryItemViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

final class HistoryItemCoverView: StreamReusableView {
    
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    
    private var videoIndicator = Label(icon: "+", size: 24)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        addSubview(imageView)
        addSubview(videoIndicator)
        imageView.snp_makeConstraints { $0.edges.equalTo(self) }
        videoIndicator.snp_makeConstraints {
            $0.right.equalTo(self).inset(2)
            $0.top.equalTo(self).inset(22)
        }
    }
    
    override func setup(entry: AnyObject?) {
        if let candy = entry as? Candy {
            imageView.url = candy.asset?.large
            videoIndicator.hidden = candy.mediaType != .Video
        }
    }
}

final class HistoryItemViewController: WLBaseViewController {
    
    private let nameLabel = Label(preset: .Normal, weight: UIFontWeightLight, textColor: UIColor.whiteColor())
    
    private let dateLabel = Label(preset: .Smaller, weight: UIFontWeightLight, textColor: UIColor.whiteColor())
    
    private let coverStreamView = StreamView()
    
    private lazy var coverDataSource: StreamDataSource = StreamDataSource(streamView: self.coverStreamView)
    
    var item: HistoryItem?
    
    @IBOutlet weak var streamView: StreamView!
    
    private lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    
    override func loadView() {
        super.loadView()
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
    }
    
    override func viewDidLoad() {
        nameLabel.text = item?.history.wrap?.name
        dateLabel.text = item?.date.stringWithFormat("EEE MMM d, yyyy")
        
        super.viewDidLoad()
        
        coverStreamView.userInteractionEnabled = false
        coverStreamView.horizontal = true
        coverDataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<HistoryItemCoverView>(), size: view.width))
        
        streamView.layout = SquareGridLayout(horizontal: false)
        dataSource.offsetForGridColumns = view.width * 0.6
        dataSource.placeholderMetrics = StreamMetrics(loader: PlaceholderView.singleDayPlaceholderLoader())
        dataSource.placeholderMetrics?.isSeparator = true
        dataSource.numberOfGridColumns = 3
        dataSource.layoutSpacing = Constants.pixelSize
        
        let metrics = dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<CandyCell>()))
        metrics.selection = { [weak self] (item, entry) -> Void in
            self?.streamView.lock()
            CandyEnlargingPresenter.handleCandySelection(item, entry: entry, historyItem: self?.item, dismissingView: { (presenter, candy) -> UIView? in
                guard let streamCandyItem = self?.streamView.itemPassingTest({ ($0.entry as? Candy) == candy}) else { return nil }
                self?.streamView.scrollRectToVisible(streamCandyItem.frame, animated: true)
                return streamCandyItem.view
            })
        }
        dataSource.items = item?.candies
        item?.history.addReceiver(self)
        
        if streamView.itemPassingTest({ !$0.visible }) != nil {
            recursivelyUpdateCover(false)
        } else {
            coverDataSource.items = item?.candies
            setCoverCandy(item?.candies.first, animated: false)
        }
    }
    
    private var coverCandy: Candy?
    
    private func setCoverCandy(candy: Candy?, animated: Bool) {
        coverCandy = candy
        coverStreamView.scrollToItemPassingTest({ $0.entry === candy }, animated: animated)
    }
    
    private func recursivelyUpdateCover(animated: Bool) {
        coverDataSource.items = item?.candies
        if let currentCandy = coverCandy, let index = item?.candies.indexOf(currentCandy) {
            let candy = item?.candies[safe: index + 1] ?? item?.candies.first
            setCoverCandy(candy, animated: animated)
        } else {
            setCoverCandy(item?.candies.first, animated: animated)
        }
        Dispatch.mainQueue.after(4) { [weak self] _ in self?.recursivelyUpdateCover(true) }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.unlock()
        streamView.reload()
    }
}

extension HistoryItemViewController: ListNotifying {
    func listChanged(list: List) {
        guard let item = item else { return }
        dataSource.items = item.candies
        if let candy = coverCandy where !item.candies.contains(candy) {
            coverCandy = item.candies.first
        }
        if item.candies.count == 0 {
            if let items = item.history.entries as? [HistoryItem] {
                for _item in items where _item.date.isSameDay(item.date) {
                    self.item = _item
                    dataSource.items = _item.candies
                    
                }
            }
        }
    }
}
