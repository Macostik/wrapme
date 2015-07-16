//
//  Country.swift
//  wrapLive
//
//  Created by Sergey Maximenko on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

import Foundation

class Country : NSObject {
    
    var name: String!
    var callingCode: String!
    var code: String!
    
    class var currentCountry : Country {
        
        get {
            var code: NSString = WLTelephony.countryCode()
            if (!code.nonempty) {
                code = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode)!.lowercaseString
            }
            var countries = Country.all()
            
            for country in countries {
                if (country.code.lowercaseString == code) {
                    return country
                }
            }
            return countries.first!
        }
    }
    
    class func all () -> Array <Country> {
        var path = NSBundle.mainBundle().pathForResource("CountryCodes", ofType: "json")
        var data = NSData(contentsOfFile: path!)
        var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as! Array<Dictionary<String,String>>
        var countries: Array<Country> = []
        for item in json {
            var country = Country();
            country.name = item["name"]
            country.callingCode = item["dial_code"]
            country.code = item["code"]
            countries.append(country)
        }
        return countries;
    }
    
}