//
//  RecentCandiesView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class RecentCandiesView: StreamReusableView {

    @IBOutlet weak var streamView: StreamView!
    
    var dataSource: StreamDataSource!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dataSource = StreamDataSource(streamView: streamView)
        dataSource.numberOfGridColumns = 3
        dataSource.sizeForGridColumns = 0.333
        streamView.layout = SquareGridLayout(horizontal: false)
        dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<CandyCell>())).disableMenu = true
        dataSource.layoutSpacing = Constants.pixelSize
    }
    
    override func setup(entry: AnyObject) {
        guard let wrap = entry as? Wrap, let recentCandies = wrap.recentCandies else {
            return
        }
        layoutIfNeeded()
        dataSource.numberOfItems = NSNumber(integer: (recentCandies.count > Constants.recentCandiesLimit_2) ? Constants.recentCandiesLimit : Constants.recentCandiesLimit_2)
        dataSource.items = recentCandies
    }

}
