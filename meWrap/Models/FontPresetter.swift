//
//  FontPresetter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol FontPresetting {
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter)
}

class FontPresetter: WLBroadcaster {
    
    static let defaultPresetter = FontPresetter()
    
    override func setup() {
        super.setup()
        NSNotificationCenter.defaultCenter().addObserverForName(UIContentSizeCategoryDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [unowned self] (_) -> Void in
            self.broadcast({ (receiver) -> Void in
                receiver.presetterDidChangeContentSizeCategory?(self)
            })
        }
    }
    
    var contentSizeCategory: String {
        return UIApplication.sharedApplication().preferredContentSizeCategory
    }
}
