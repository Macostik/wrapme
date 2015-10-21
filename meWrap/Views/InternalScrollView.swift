//
//  InternalScrollView.swift
//  meWrap
//
//  Created by Yura Granchenko on 21/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class InternalScrollView : UIScrollView, UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (self.contentOffset.y != 0) {
            self.setContentOffset(CGPointZero, animated: true)
            return false
        }
        return true;
    }
}