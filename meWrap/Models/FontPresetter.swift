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

class FontPresetter: Notifier {
    
    static let defaultPresetter = FontPresetter()
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserverForName(UIContentSizeCategoryDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [unowned self] (_) -> Void in
            self.notify({ (receiver) -> Void in
                receiver.presetterDidChangeContentSizeCategory?(self)
            })
        }
    }
    
    var contentSizeCategory: String {
        return UIApplication.sharedApplication().preferredContentSizeCategory
    }
}
