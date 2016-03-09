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
        NSNotificationCenter.defaultCenter().addObserverForName(UIContentSizeCategoryDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] (_) -> Void in
            if let weakSelf = self {
                weakSelf.notify({ $0.presetterDidChangeContentSizeCategory?(weakSelf) })
            }
        }
    }
    
    var contentSizeCategory: String {
        return UIApplication.sharedApplication().preferredContentSizeCategory
    }
}
