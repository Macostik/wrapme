//
//  NSDate+Formatting.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/6/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

var defaultFormat = "MMM d, yyyy"
private var _formatters = [String:NSDateFormatter]()

extension NSDateFormatter {

    class func formatter() -> NSDateFormatter {
        return formatterWithDateFormat(defaultFormat)
    }
    
    class func formatterWithDateFormat(format: String) -> NSDateFormatter {
        var formatters = _formatters
        if let formatter = formatters[format] {
            return formatter
        }
        let formatter = NSDateFormatter()
        formatter.dateFormat = format
        formatter.AMSymbol = "am"
        formatter.PMSymbol = "pm"
        _formatters[format] = formatter
        NSNotificationCenter.defaultCenter().addObserverForName(NSSystemTimeZoneDidChangeNotification, object: nil, queue: nil, usingBlock: { (n) -> Void in
            formatter.timeZone = NSTimeZone.systemTimeZone()
        })
        return formatter
    }
    
    class func formatterWithDateStyle(dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle) -> NSDateFormatter {
        return formatterWithDateStyle(dateStyle, timeStyle: timeStyle, relative: false)
    }
    
    class func formatterWithDateStyle(dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle, relative: Bool) -> NSDateFormatter {
        var formatters = _formatters
        let key = "\(dateStyle.rawValue)-\(timeStyle.rawValue)-\(relative)"
        if let formatter = formatters[key] {
            return formatter
        }
        let formatter = NSDateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.doesRelativeDateFormatting = relative
        _formatters[key] = formatter
        NSNotificationCenter.defaultCenter().addObserverForName(NSSystemTimeZoneDidChangeNotification, object: nil, queue: nil, usingBlock: { (n) -> Void in
            formatter.timeZone = NSTimeZone.systemTimeZone()
        })
        return formatter
    }
    
}

extension NSDate {
    func stringWithFormat(format: String) -> String {
        return NSDateFormatter.formatterWithDateFormat(format).stringFromDate(self)
    }
    func string() -> String {
        return NSDateFormatter.formatter().stringFromDate(self)
    }
    func stringWithTimeStyle(timeStyle: NSDateFormatterStyle) -> String {
        return NSDateFormatter.formatterWithDateStyle(.NoStyle, timeStyle: timeStyle).stringFromDate(self)
    }
    func stringWithDateStyle(dateStyle: NSDateFormatterStyle) -> String {
        return NSDateFormatter.formatterWithDateStyle(dateStyle, timeStyle: .NoStyle).stringFromDate(self)
    }
    func stringWithDateStyle(dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle) -> String {
        return NSDateFormatter.formatterWithDateStyle(dateStyle, timeStyle: timeStyle).stringFromDate(self)
    }
    func stringWithDateStyle(dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle, relative: Bool) -> String {
        return NSDateFormatter.formatterWithDateStyle(dateStyle, timeStyle: timeStyle, relative: relative).stringFromDate(self)
    }
}

extension NSString {
    func dateWithFormat(format: String) -> NSDate? {
        return NSDateFormatter.formatterWithDateFormat(format).dateFromString(self as String)
    }
    func date() -> NSDate? {
        return NSDateFormatter.formatter().dateFromString(self as String)
    }
}