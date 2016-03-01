//
//  StreamReusableView.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class StreamReusableView: UIView, UIGestureRecognizerDelegate {
    
    var entry: AnyObject? {
        didSet {
            setup(entry)
        }
    }
    
    var metrics: StreamMetrics?
    var item: StreamItem?
    var selected: Bool = false
    lazy var selectTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "select")
    
    private weak var _contentView: UIView?
    @IBOutlet weak var contentView: UIView! {
        set { _contentView = newValue }
        get { return _contentView ?? self }
    }
    
    func layoutWithMetrics(metrics: StreamMetrics) {}
    
    func loadedWithMetrics(metrics: StreamMetrics) {
        selectTapGestureRecognizer.delegate = self
        self.addGestureRecognizer(selectTapGestureRecognizer)
    }
    
    func setup(entry: AnyObject?) {}
    
    func resetup() {
        setup(entry)
    }
    
    override func select(entry: AnyObject?) {
        metrics?.select(item, entry: entry)
    }
    
    @IBAction func select() {
        select(entry)
    }
    
    func didDequeue() {}
    
    func willEnqueue() {}
    
    // MARK: - UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer != selectTapGestureRecognizer || metrics?.selectable ?? false
    }
}