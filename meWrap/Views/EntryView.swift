//
//  EntryView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class EntryView<T: Entry>: EntryStreamReusableView<T>, EntryNotifying {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        T.notifier().addReceiver(self)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        resetup()
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return self.entry === entry
    }
}

class UserView: EntryView<User> {
    
    @IBOutlet weak var avatarView: ImageView?
    
    @IBOutlet weak var nameLabel: UILabel?
    
    override func setup(user: User) {
        avatarView?.url = user.avatar?.small
        nameLabel?.text = user.name
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let avatarView = avatarView {
            avatarView.borderWidth = Constants.pixelSize
            avatarView.borderColor = UIColor.whiteColor()
            avatarView.circled = true
        }
        entry = User.currentUser
    }
}

class WrapView: EntryView<Wrap> {
    
    @IBOutlet weak var coverView: WrapCoverView?
    
    @IBOutlet weak var nameLabel: UILabel?
    
    override func setup(wrap: Wrap) {
        if let coverView = coverView {
            coverView.url = wrap.asset?.small
            coverView.isFollowed = wrap.isPublic ? wrap.isContributing : false
            coverView.isOwner = wrap.isPublic ? (wrap.contributor?.current ?? false) : false
        }
        nameLabel?.text = wrap.name
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        coverView?.circled = true
    }
}