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

class SegmentedControl: UIControl {
    
    private var controls = [UIControl]()
    
    @IBOutlet weak var selectionConstraint: NSLayoutConstraint?

    var selectedSegment: Int {
        get {
            return controls.indexOf({ $0.selected }) ?? NSNotFound
        }
        set {
            setSelectedControl(controlForSegment(newValue))
        }
    }
    
    @IBOutlet weak var delegate: SegmentedControlDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        var selectedSegment: Int?
        for view in subviews {
            if let control = view as? UIControl {
                control.addTarget(self, action: "selectSegmentTap:", forControlEvents: .TouchDown)
                controls.append(control)
                if control.selected {
                    selectedSegment = controls.indexOf(control)
                }
            }
        }
        if let segment = selectedSegment {
            self.selectedSegment = segment
        }
    }
    
    func deselect() {
        selectedSegment = NSNotFound
    }
    
    func selectSegmentTap(sender: UIControl) {
        if let index = controls.indexOf(sender) where !sender.selected {
            
            guard (delegate?.segmentedControl?(self, shouldSelectSegment:index) ?? true) else {
                return
            }
            
            setSelectedControl(sender)
            delegate?.segmentedControl?(self, didSelectSegment:index)
            sendActionsForControlEvents(.ValueChanged)
        }
    }
    
    func setSelectedControl(control: UIControl?) {
        for _control in controls {
            _control.selected = _control == control
            if _control.selected {
                selectionConstraint?.constant = _control.x
                setNeedsLayout()
            }
        }
    }
    
    func controlForSegment(segment: Int) -> UIControl? {
        if segment >= 0 && segment < controls.count {
            return controls[segment]
        } else {
            return nil
        }
    }
}
