//
//  WhatsUpEvent.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class WhatsUpEvent: NSObject {
    
    var event: Event
    
    var contribution: Contribution
    
    var date: NSDate? {
        return event == .Update ? contribution.updatedAt : contribution.createdAt
    }
    
    init(event: Event, contribution: Contribution) {
        self.event = event
        self.contribution = contribution
        super.init()
    }
}
