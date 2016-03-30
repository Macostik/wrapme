//
//  EntryStatusIndicator.swift
//  meWrap
//
//  Created by Yura Granchenko on 22/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

private let IndicatorWidth: CGFloat = 16.0

final class EntryStatusIndicator: UILabel, EntryNotifying {
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint?
    
    var contribution : Contribution?
    
    convenience init(color: UIColor) {
        self.init(frame: CGRect.zero)
        font = UIFont.icons(13)
        textColor = color
    }
    
    func identityByContributorStatus(contribution: Contribution!) -> String! {
        if let container = contribution.container as? Contribution where container.status != .Finished {
            return "D"
        }
        
        switch contribution.status {
        case .Ready: return "?"
        case .InProgress: return "E"
        case .Finished: return "F"
        }
    }
    
    func updateStatusIndicator(contribution : Contribution) {
        self.hidden = !contribution.valid || !(contribution.contributor?.current ?? false)
        if let widthConstraint = widthConstraint {
            UIView.performWithoutAnimation({ () -> Void in
                widthConstraint.constant = self.hidden ? 0.0 : IndicatorWidth
                self.layoutIfNeeded()
            })
        }
        if self.contribution != contribution {
            self.contribution = contribution
            contribution.dynamicType.notifier().addReceiver(self)
            if let container = contribution.container as? Contribution {
                if container.status != .Finished {
                    container.dynamicType.notifier().addReceiver(self)
                }
            }
            self.text = self.identityByContributorStatus(contribution)
        }
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        self.text = self.identityByContributorStatus(contribution!)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        if let contribution = contribution {
            return contribution == entry || (contribution.container != nil && entry == contribution.container)
        } else {
            return false
        }
    }
}




