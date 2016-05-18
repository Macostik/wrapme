//
//  ExpandableView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 4/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class ExpandableView: UIView {
    
    var expandingConstraint: Constraint?
    
    var expanded = false {
        willSet {
            if newValue != expanded {
                if newValue {
                    expandingConstraint?.activate()
                } else {
                    expandingConstraint?.deactivate()
                }
            }
        }
    }
    
    func makeExpandable(@noescape block: (expandingConstraint: inout Constraint?) -> ()) {
        var constraint: Constraint?
        block(expandingConstraint: &constraint)
        expandingConstraint = constraint
        if expanded == false {
            constraint?.deactivate()
        }
    }
}