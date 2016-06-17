//
//  SegmentedControl.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol SegmentedControlDelegate {
    optional func segmentedControl(control: SegmentedControl, didSelectSegment segment: Int)
    optional func segmentedControl(control: SegmentedControl, shouldSelectSegment segment: Int) -> Bool
}

final class SegmentedControl: UIControl {
    
    private var controls: [UIControl] = []
    
    func setControls(controls: [UIControl]) {
        self.controls = controls
        controls.all({ $0.addTarget(self, action: #selector(self.selectSegmentTap(_:)), forControlEvents: .TouchUpInside) })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let controls = subviews.reduce([UIControl](), combine: {
            if let control = $1 as? UIControl {
                return $0 + [control]
            } else {
                return $0
            }
        })
        setControls(controls)
    }
    
    var selectedSegment: Int {
        get { return controls.indexOf({ $0.selected }) ?? NSNotFound }
        set { setSelectedControl(controlForSegment(newValue)) }
    }
    
    @IBOutlet weak var delegate: SegmentedControlDelegate?
    
    func deselect() {
        selectedSegment = NSNotFound
    }
    
    func selectSegmentTap(sender: UIControl) {
        if let index = controls.indexOf(sender) where !sender.selected {
            
            guard (delegate?.segmentedControl?(self, shouldSelectSegment:index) ?? true) else { return }
            
            setSelectedControl(sender)
            delegate?.segmentedControl?(self, didSelectSegment:index)
            sendActionsForControlEvents(.ValueChanged)
        }
    }
    
    private func setSelectedControl(control: UIControl?) {
        controls.all({ $0.selected = $0 == control })
    }
    
    func controlForSegment(segment: Int) -> UIControl? {
        return controls[safe: segment]
    }
}
