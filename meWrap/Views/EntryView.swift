//
//  EntryView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class EntryView: StreamReusableView, EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        setup(entry)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return self.entry === entry
    }
}

class UserView: EntryView {
    
    @IBOutlet weak var avatarView: ImageView?
    
    @IBOutlet weak var nameLabel: UILabel?
    
    override func setup(entry: AnyObject?) {
        if let user = entry as? User {
            avatarView?.url = user.avatar?.small
            nameLabel?.text = user.name
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        User.notifier().addReceiver(self)
        if let avatarView = avatarView {
            avatarView.borderWidth = Constants.pixelSize * 2.0
            avatarView.borderColor = UIColor.whiteColor()
            avatarView.circled = true
        }
        entry = User.currentUser
    }
}

class WrapView: EntryView {
    
    @IBOutlet weak var coverView: WrapCoverView?
    
    @IBOutlet weak var nameLabel: UILabel?
    
    override func setup(entry: AnyObject?) {
        if let wrap = entry as? Wrap {
            if let coverView = coverView {
                coverView.url = wrap.asset?.small
                coverView.isFollowed = wrap.isPublic ? wrap.isContributing : false
                coverView.isOwner = wrap.isPublic ? (wrap.contributor?.current ?? false) : false
            }
            nameLabel?.text = wrap.name;
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Wrap.notifier().addReceiver(self)
        coverView?.circled = true
    }
}