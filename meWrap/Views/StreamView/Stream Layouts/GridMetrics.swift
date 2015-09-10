//
//  GridMetrics.swift
//  16wrap
//
//  Created by Sergey Maximenko on 9/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

class GridMetrics: StreamMetrics {
    
    @IBInspectable var ratio: CGFloat = 0
    
    var ratioAt: (StreamPosition, GridMetrics) -> CGFloat = { index, metrics in
        return metrics.ratio;
    }
    
    convenience init(identifier: String, ratio: CGFloat) {
        self.init(identifier: identifier)
        self.ratio = ratio
    }
}
