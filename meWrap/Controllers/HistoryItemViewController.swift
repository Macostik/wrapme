//
//  HistoryItemViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class HistoryItemViewController: WLBaseViewController {
    
    weak var item: HistoryItem?
    
    @IBOutlet weak var streamView: StreamView!
    
    var dataSource: StreamDataSource!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = item?.history.wrap?.name
        dateLabel.text = item?.date.stringWithDateStyle(.MediumStyle)
        streamView.layout = SquareGridLayout(horizontal: false)
        dataSource = StreamDataSource(streamView: streamView)
        dataSource.numberOfGridColumns = 3
        dataSource.layoutSpacing = Constants.pixelSize
        let metrics = dataSource.addMetrics(StreamMetrics(identifier: "CandyCell"))
        metrics.selection = { [weak self] (item, entry) -> Void in
            CandyEnlargingPresenter.handleCandySelection(item, entry: entry, historyItem: self?.item, dismissingView: { (presenter, candy) -> UIView? in
                guard let streamCandyItem = self?.streamView.itemPassingTest({ ($0.entry as? Candy) == candy}) else { return nil }
                self?.streamView.scrollRectToVisible(streamCandyItem.frame, animated: true)
                return streamCandyItem.view
            })
        }
        dataSource.items = item?.candies
        item?.history.addReceiver(self)
    }
}

extension HistoryItemViewController: ListNotifying {
    func listChanged(list: List) {
        dataSource.items = item?.candies
    }
}
