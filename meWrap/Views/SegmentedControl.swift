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
    
    private lazy var controls: [UIControl] = {
        var controls = [UIControl]()
        for view in self.subviews {
            if let control = view as? UIControl {
                controls.append(control)
            }
        }
        return controls
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        for control in controls {
            control.addTarget(self, action: #selector(SegmentedControl.selectSegmentTap(_:)), forControlEvents: .TouchUpInside)
        }
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
        for _control in controls {
            _control.selected = _control == control
        }
    }
    
    func controlForSegment(segment: Int) -> UIControl? {
        return controls[safe: segment]
    }
}
