//
//  Telephony.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/21/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CoreTelephony
import MessageUI

class Telephony: NSObject {
    
    static var countryCode: String? {
        let networkInfo = CTTelephonyNetworkInfo()
        return networkInfo.subscriberCellularProvider?.isoCountryCode?.lowercaseString
    }
    
    static var hasPhoneNumber: Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        return MFMessageComposeViewController.canSendText() && networkInfo.subscriberCellularProvider?.mobileCountryCode != nil
    }
}