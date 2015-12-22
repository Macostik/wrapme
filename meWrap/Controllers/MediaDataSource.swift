//
//  MediaDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class MediaDataSource: PaginatedStreamDataSource {
    
    var liveBroadcasts: (Void -> [LiveBroadcast]?)?
    
    var liveBroadcastMetrics = StreamMetrics { (metrics) -> Void in
        metrics.size = 70
        metrics.isSeparator = true
    }
    
    override func streamViewNumberOfSections(streamView: StreamView) -> Int {
        return 2;
    }
    
    override func streamView(streamView: StreamView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return liveBroadcasts?()?.count ?? 0
        } else {
            return super.streamView(streamView, numberOfItemsInSection: section)
        }
    }
    
    override func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetrics] {
        if position.section == 0 {
            return [liveBroadcastMetrics]
        } else {
            return metrics
        }
    }
    
    override func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)? {
        let position = item.position
        if position.section == 0 {
            return { [weak self] _ in
                return self?.liveBroadcasts?()?[position.index]
            }
        } else {
            return super.streamView(streamView, entryBlockForItem: item)
        }
    }
    
}