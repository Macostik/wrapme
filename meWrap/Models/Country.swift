//
//  Country.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/21/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CoreTelephony
import MessageUI

struct Telephony {
    
    static var countryCode: String? {
        let networkInfo = CTTelephonyNetworkInfo()
        return networkInfo.subscriberCellularProvider?.isoCountryCode?.lowercaseString
    }
    
    static var hasPhoneNumber: Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        return MFMessageComposeViewController.canSendText() && networkInfo.subscriberCellularProvider?.mobileCountryCode != nil
    }
}

final class Country {
    var name: String!
    var callingCode: String!
    var code: String!
    
    static var allCountries: [Country] {
        guard let path = NSBundle.mainBundle().pathForResource("country-codes", ofType: "json"),
            let data = NSData(contentsOfFile: path) else {
            return []
        }
        guard let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)) as? [[String : String]] else {
            return []
        }
        return json.map({
            let country = Country()
            country.name = $0["name"]
            country.callingCode = $0["dial_code"]
            country.code = $0["code"]
            return country
        })
    }
    
    class func currentCountry() -> Country {
        let code = Telephony.countryCode ?? NSLocale.currentLocale().objectForKey(NSLocaleCountryCode)?.lowercaseString
        let countries = Country.allCountries
        return countries[{ $0.code?.lowercaseString == code }] ?? countries.first!
    }
}