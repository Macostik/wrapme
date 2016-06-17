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
    let selectTapGestureRecognizer = UITapGestureRecognizer()
    
    func layoutWithMetrics(metrics: StreamMetricsProtocol) {}
    
    func didLoad() {
        selectTapGestureRecognizer.addTarget(self, action: #selector(self.selectAction))
        selectTapGestureRecognizer.delegate = self
        self.addGestureRecognizer(selectTapGestureRecognizer)
    }
    
    @IBAction func selectAction() {
        metrics?.select(self)
    }
    
    func didDequeue() {}
    
    func willEnqueue() {}
    
    func resetup() {}
    
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
            resetup()
        }
    }
    
    func setup(entry: T) {}
    
    func setupEmpty() {}
    
    override func resetup() {
        if let entry = entry {
            setup(entry)
        } else {
            setupEmpty()
        }
    }
}
