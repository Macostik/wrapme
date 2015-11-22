//
//  EntryView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class EntryView: UIView {
    
    var entry: Entry? {
        didSet {
            if let entry = entry {
                update(entry)
            }
        }
    }
    
    class func entityName() -> String? {
        return nil
    }
    
    func update(entry: Entry) {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let name = self.dynamicType.entityName() {
            EntryNotifier.notifierForName(name)
        }
    }
}

extension EntryView: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        update(entry)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return self.entry == entry
    }
}

class UserView: EntryView {
    
    @IBOutlet weak var avatarView: WLImageView?
    
    @IBOutlet weak var nameLabel: UILabel?
    
    override class func entityName() -> String? {
        return User.entityName()
    }
    
    override func update(entry: Entry) {
        if let user = entry as? User {
            avatarView?.url = user.picture?.small
            nameLabel?.text = user.name
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let avatarView = avatarView {
            avatarView.borderWidth = Constants.pixelSize * 2.0
            avatarView.borderColor = UIColor.whiteColor()
            avatarView.circled = true
        }
        entry = User.currentUser
    }
}

class WrapView: EntryView {
    
    @IBOutlet weak var coverView: WLWrapStatusImageView?
    
    @IBOutlet weak var nameLabel: UILabel?
    
    override class func entityName() -> String? {
        return Wrap.entityName()
    }
    
    override func update(entry: Entry) {
        if let wrap = entry as? Wrap {
            if let coverView = coverView {
                coverView.url = wrap.picture?.small
                coverView.isFollowed = wrap.isPublic ? wrap.isContributing : false
                coverView.isOwner = wrap.isPublic ? (wrap.contributor?.current ?? false) : false
            }
            nameLabel?.text = wrap.name;
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        coverView?.circled = true
    }
}