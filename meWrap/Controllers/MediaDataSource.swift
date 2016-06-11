//
//  MediaDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class MediaDataSource: PaginatedStreamDataSource<History> {
    
    weak var wrap: Wrap?
    
    var liveBroadcastMetrics = specify(StreamMetrics<LiveBroadcastMediaView>()) {
        $0.size = 70
        $0.isSeparator = true
    }
    
    override func numberOfSections() -> Int {
        return 2
    }
    
    override func numberOfItemsIn(section: Int) -> Int {
        if section == 0 {
            return wrap?.liveBroadcasts.count ?? 0
        } else {
            return super.numberOfItemsIn(section)
        }
    }
    
    override func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol] {
        if position.section == 0 {
            return [liveBroadcastMetrics]
        } else {
            return metrics
        }
    }
    
    override func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)? {
        let position = item.position
        if position.section == 0 {
            return { [weak self] _ in
                return self?.wrap?.liveBroadcasts[safe: position.index]
            }
        } else {
            return super.entryBlockForItem(item)
        }
    }
}