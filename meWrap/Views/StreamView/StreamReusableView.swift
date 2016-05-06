//
//  StreamReusableView.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class StreamReusableView: UIView, UIGestureRecognizerDelegate {
    
    func setEntry(entry: AnyObject?) {}
    func getEntry() -> AnyObject? { return nil }
    
    var metrics: StreamMetricsProtocol?
    var item: StreamItem?
    var selected: Bool = false
    lazy var selectTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(StreamReusableView.select as (StreamReusableView) -> () -> ()))
    
    func layoutWithMetrics(metrics: StreamMetricsProtocol) {}
    
    func didLoad() {
        selectTapGestureRecognizer.delegate = self
        self.addGestureRecognizer(selectTapGestureRecognizer)
    }
    
    @IBAction func select() {
        metrics?.select(self)
    }
    
    func didDequeue() {}
    
    func willEnqueue() {}
    
    // MARK: - UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer != selectTapGestureRecognizer || metrics?.selectable ?? false
    }
}

class EntryStreamReusableView<T: AnyObject>: StreamReusableView {
    
    init() {
        super.init(frame: CGRect.zero)
    }
    
    override func setEntry(entry: AnyObject?) {
        self.entry = entry as? T
    }

    override func getEntry() -> AnyObject? {
        return entry
    }
    
    var entry: T? {
        didSet {
            didSetEntry()
        }
    }
    
    private func didSetEntry() {
        if let entry = entry {
            setup(entry)
        } else {
            setupEmpty()
        }
    }
    
    func setup(entry: T) {}
    
    func setupEmpty() {}
    
    func resetup() {
        didSetEntry()
    }
}
