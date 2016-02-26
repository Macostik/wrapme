//
//  GeometryHelper.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/26/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

extension CGSize {
    
    func fit(size: CGSize) -> CGSize {
        let scale = min(width / size.width, height / size.height)
        return CGSizeMake(size.width * scale, size.height * scale)
    }
    
    func fill(size: CGSize) -> CGSize {
        let scale = max(width / size.width, height / size.height)
        return CGSizeMake(size.width * scale, size.height * scale)
    }
    
    func rectCenteredInSize(size: CGSize) -> CGRect {
        return CGRect(origin: CGPointMake(size.width/2 - width/2, size.height/2 - height/2), size: self)
    }
}

func smoothstep(_min: CGFloat = 0, _ _max: CGFloat = 1, _ value: CGFloat) -> CGFloat {
    return max(_min, min(_max, value))
}

extension CGPoint {
    
    func offset(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPointMake(self.x + x, self.y + y)
    }
}
