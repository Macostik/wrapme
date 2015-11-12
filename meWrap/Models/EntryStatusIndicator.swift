//
//  EntryStatusIndicator.swift
//  meWrap
//
//  Created by Yura Granchenko on 22/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

let WLIndicatorWidth:CGFloat = 16.0

class EntryStatusIndicator: UILabel, EntryNotifying {
    
    @IBOutlet weak  var widthConstraint : NSLayoutConstraint?;
    var contribution : Contribution?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func identityByContributorStatus(contribution: Contribution!) -> String! {
        if let container = contribution.container as? Contribution where container.status != .Finished {
            return "D"
        }
        
        switch contribution.status {
        case .Ready:return "D"
        case .InProgress: return "E"
        case .Finished: return "F"
        }
    }
    
    func updateStatusIndicator(contribution : Contribution) {
        self.hidden = !contribution.valid || !(contribution.contributor?.current ?? false)
        if let widthConstraint = widthConstraint {
            UIView.performWithoutAnimation({ () -> Void in
                widthConstraint.constant = self.hidden ? 0.0 : WLIndicatorWidth;
                self.layoutIfNeeded()
            })
        }
        if self.contribution != contribution {
            self.contribution = contribution;
            contribution.dynamicType.notifier().addReceiver(self)
            if let container = contribution.container as? Contribution {
                if container.status != .Finished {
                    container.dynamicType.notifier().addReceiver(self)
                }
            }
            self.setIconNameByCotribution(contribution)
        }
    }
    
    func setIconNameByCotribution(contribution : Contribution) {
       self.text = self.identityByContributorStatus(contribution);
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry) {
        self.setIconNameByCotribution(contribution!);
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        if let contribution = contribution {
            return contribution == entry || (contribution.container != nil && entry == contribution.container)
        } else {
            return false
        }
    }
}




