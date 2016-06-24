//
//  HomeDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class HomeDataSource: PaginatedStreamDataSource<PaginatedList<Wrap>> {
    
    required init(streamView: StreamView) {
        super.init(streamView: streamView)
    }
    
    override func didSetItems() {
        super.didSetItems()
        if let items = items where items.count > 0 {
            wrap = items.entries.first
        }
    }
    
    weak var wrap: Wrap? {
        didSet {
            if let wrap = wrap where wrap != oldValue {
                fetchTopWrapIfNeeded(wrap)
            }
        }
    }
    
    func fetchTopWrapIfNeeded(wrap: Wrap) {
        if wrap.candies.count < Constants.recentCandiesLimit {
            RunQueue.fetchQueue.run({ [weak wrap] (finish) -> Void in
                if let wrap = wrap where wrap.valid {
                    wrap.fetch({ _ in finish() }, failure: { _ in finish() })
                } else {
                    finish()
                }
            })
        }
    }
    
    override func numberOfItemsIn(section: Int) -> Int {
        wrap = items?.entries.first
        return super.numberOfItemsIn(section)
    }
}
