//
//  EntryView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class WrapView: UIView {
    
    @IBOutlet weak var coverView: WrapCoverView?
    
    @IBOutlet weak var nameLabel: UILabel?
    
    weak var wrap: Wrap? {
        didSet {
            if let wrap = wrap {
                setup(wrap)
            }
        }
    }
    
    func setup(wrap: Wrap) {
        if let coverView = coverView {
            coverView.url = wrap.asset?.small
            coverView.isFollowed = wrap.isPublic ? wrap.isContributing : false
            coverView.isOwner = wrap.isPublic ? (wrap.contributor?.current ?? false) : false
        }
        nameLabel?.text = wrap.name
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Wrap.notifier().addReceiver(self)
        coverView?.circled = true
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if let wrap = wrap {
            setup(wrap)
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap === entry
    }
}