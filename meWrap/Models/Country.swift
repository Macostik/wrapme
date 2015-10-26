//
//  Country.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/21/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class Country: NSObject {
    var name: String?
    var callingCode: String?
    var code: String?
    
    static var allCountries: Array<Country> {
        guard let path = NSBundle.mainBundle().pathForResource("CountryCodes", ofType: "json"),
            let data = NSData(contentsOfFile: path) else {
            return []
        }
        var countries = Array<Country>()
        do {
            guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? Array<Dictionary<String, String>> else {
                return []
            }
            for dictionary in json {
                let country = Country()
                country.name = dictionary["name"]
                country.callingCode = dictionary["dial_code"]
                country.code = dictionary["code"]
                countries.append(country)
            }
        } catch {
        }
        return countries
    }
    
    static var getCurrentCountry: Country? {
        var code = Telephony.countryCode
        if code == nil {
            code = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode)?.lowercaseString
        }
        let countries = Country.allCountries
        for country in countries {
            if country.code?.lowercaseString == code {
                return country;
            }
        }
        return countries.first
    }
}