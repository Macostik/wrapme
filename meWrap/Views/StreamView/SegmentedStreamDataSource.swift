//
//  SegmentedStreamDataSource.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class SegmentedStreamDataSource: StreamDataSource, SegmentedControlDelegate {
    
    @IBOutlet var dataSources: [StreamDataSource] = []
    
    @IBOutlet override weak var streamView: StreamView? {
        didSet {
            for dataSource in dataSources {
                dataSource.streamView = streamView
            }
            if currentDataSource == nil {
                currentDataSource = dataSources.first
            }
        }
    }
    
    var currentDataSource: StreamDataSource? {
        didSet {
            if let dataSource = currentDataSource, let streamView = streamView {
                streamView.delegate = dataSource
                dataSource.reload()
            }
        }
    }
    
    override func reload() {
        currentDataSource?.reload()
    }
    
    override func refresh(success: WLArrayBlock?, failure: WLFailureBlock?) {
        currentDataSource?.refresh(success, failure: failure)
    }
    
    func setCurrentDataSourceAt(index: Int) {
        if index < dataSources.count {
            let dataSource = dataSources[index]
            currentDataSource = dataSource
            dataSource.streamView?.setMinimumContentOffsetAnimated(false)
        }
    }
}

extension SegmentedStreamDataSource {
    // MARK: - SegmentedControlDelegate
    
    func segmentedControl(control: SegmentedControl!, didSelectSegment segment: Int) {
        setCurrentDataSourceAt(segment)
    }
    
    @IBAction func segmentValueChanged(sender: SegmentedControl) {
        setCurrentDataSourceAt(sender.selectedSegment)
    }
}