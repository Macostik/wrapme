//
//  HomeDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class HomeDataSource: PaginatedStreamDataSource {
    
    override func didSetItems() {
        super.didSetItems()
        if let items = items where items.count > 0 {
            wrap = items.tryAt(0) as? Wrap
        }
    }
    
    var wrap: Wrap? {
        didSet {
            if let wrap = wrap where wrap != oldValue {
                fetchTopWrapIfNeeded(wrap)
            }
        }
    }
    
    func fetchTopWrapIfNeeded(wrap: Wrap) {
        if (wrap.candies?.count ?? 0) < Constants.recentCandiesLimit {
            runUnaryQueuedOperation(WLOperationFetchingDataQueue, {[weak wrap] (operation) -> Void in
                if let wrap = wrap where wrap.valid {
                    WLPaginatedRequest.wrap(wrap, contentType: WLWrapContentTypeRecent).send({ (candies) -> Void in
                        operation.finish()
                        }, failure: { (error) -> Void in
                            operation.finish()
                    })
                } else {
                    operation.finish()
                }
            })
        }
    }
    
    override func streamView(streamView: StreamView, numberOfItemsInSection section: Int) -> Int {
        wrap = items?.tryAt(0) as? Wrap
        return super.streamView(streamView, numberOfItemsInSection: section)
    }
}
