//
//  EntryStatusIndicator.swift
//  meWrap
//
//  Created by Yura Granchenko on 22/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

let WLIndicatorWidth:CGFloat = 16.0

class EntryStatusIndicator: UILabel, WLEntryNotifyReceiver {
    
    @IBOutlet weak  var widthConstraint : NSLayoutConstraint?;
    var contribution : WLContribution?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func identityByContributorStatus(contribution: WLContribution!) -> String! {
        let container = contribution.container as? WLContribution
        if container?.status != .Finished {
            return "D"
        }
        
        switch contribution.status {
        case .Ready:return "D"
        case .InProgress: return "E"
        case .Finished: return "F"
        }
    }
    
    func updateStatusIndicator(contribution : WLContribution) {
        self.hidden = contribution.invalid || !contribution.contributedByCurrentUser;
        if let widthConstraint = widthConstraint {
            UIView.performWithoutAnimation({ () -> Void in
                widthConstraint.constant = self.hidden ? 0.0 : WLIndicatorWidth;
                self.layoutIfNeeded()
            })
        }
        if self.contribution != contribution {
            self.contribution = contribution;
            let contributionClass = contribution.classForCoder
            contributionClass.notifier().addReceiver(self)
            if let container = contribution.container as? WLContribution {
                if container.status != .Finished {
                    let containerClass = container.classForCoder
                    containerClass.notifier().addReceiver(self)
                }
            }
            self.setIconNameByCotribution(contribution)
        }
    }
    
    func setIconNameByCotribution(contribution : WLContribution) {
       self.text = self.identityByContributorStatus(contribution);
    }
    
    func notifier(notifier : WLEntryNotifier, didUpdateEntry entry : WLEntry) {
        self.setIconNameByCotribution(contribution!);
    }
    
    func notifier(notifier : WLEntryNotifier, shouldNotifyOnEntry entry : WLEntry) -> Bool {
        return contribution == entry || (contribution!.container != nil && entry == contribution!.container)
    }
}




