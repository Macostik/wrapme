//
//  NSDate+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/6/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

private var _minuteInterval: NSTimeInterval = 60
private var _hourInterval: NSTimeInterval = 3600
private var _dayInterval: NSTimeInterval = 86400
private var _weekInterval: NSTimeInterval = 604800

func >(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSinceDate(rhs) > 0
}

func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSinceDate(rhs) < 0
}

extension NSDate {
    
    class func dayAgo() -> NSDate {
        return now(-_dayInterval)
    }
    
    func startOfDay() -> NSDate {
        return NSCalendar.currentCalendar().startOfDayForDate(self)
    }
    func endOfDay() -> NSDate {
        return startOfDay().dateByAddingTimeInterval(_dayInterval - 0.0001)
    }
    
    func isSameDay(date: NSDate) -> Bool {
        if abs(timeIntervalSinceDate(date)) > _dayInterval {
            return false
        }
        return NSCalendar.currentCalendar().isDate(self, inSameDayAsDate: date)
    }
    
    func isToday() -> Bool {
        return NSCalendar.currentCalendar().isDateInToday(self)
    }
    
    var timestamp: NSTimeInterval {
        return timeIntervalSince1970
    }
    
    func earlier(date: NSDate) -> Bool {
        return self < date
    }
    
    func later(date: NSDate) -> Bool {
        return self > date
    }
    
    func timestampCompare(date: NSDate) -> NSComparisonResult {
        let t1 = timestamp
        let t2 = date.timestamp
        if t1 < t2 {
            return .OrderedAscending
        } else if t1 > t2 {
            return .OrderedDescending
        } else {
            return .OrderedSame
        }
    }
    
    func timeAgoString() -> String {
    
        let interval = abs(timeIntervalSinceDate(NSDate.now()))
        
        if (interval >= _weekInterval) {
            return stringWithDateStyle(.ShortStyle, timeStyle:.NoStyle)
        } else {
            var value: NSTimeInterval = interval / _dayInterval
            var name = ""
            if value >= 1 {
                name = "day".ls
            } else  {
                value = interval / _hourInterval
                if value >= 1 {
                    name = "hour".ls
                } else {
                    value = interval / _minuteInterval
                    if value >= 1 {
                        name = "minute".ls
                    } else {
                        return "less_than_minute_ago".ls
                    }
                }
            }
            value = floor(value)
            
            return String(format: "formatted_calendar_units_ago".ls, value, name, (value == 1 ? "" : "plural_ending".ls))
        }
    }
    
    func timeAgoStringAtAMPM() -> String {
        let interval = abs(timeIntervalSinceDate(NSDate.now()))
        if (interval >= _weekInterval) {
            return stringWithDateStyle(.ShortStyle, timeStyle:.NoStyle)
        } else {
            let value = interval / _dayInterval
            if (value >= 2) {
                return String(format: "formatted_calendar_units_ago_at_time".ls, value, "day".ls, stringWithTimeStyle(.ShortStyle))
            } else {
                let name = (isToday() ? "today" : "yesterday").ls
                return String(format: "formatted_day_at_time".ls, name, stringWithTimeStyle(.ShortStyle))
            }
        }
    }
    
    class func trackServerTime(serverTime: NSDate?) {
        NSUserDefaults.sharedUserDefaults?.serverTimeDifference = serverTime?.timeIntervalSinceNow ?? 0
    }
    
    class func now() -> NSDate {
        return NSDate(timeIntervalSinceNow: NSUserDefaults.sharedUserDefaults?.serverTimeDifference ?? 0)
    }
    
    class func now(offset: NSTimeInterval) -> NSDate {
        let interval = ((NSUserDefaults.sharedUserDefaults?.serverTimeDifference ?? 0) + offset)
        return NSDate(timeIntervalSinceNow: interval)
    }
    
    class func dateWithTimestamp(timestamp: NSTimeInterval) -> NSDate {
        return NSDate(timeIntervalSince1970: NSUserDefaults.sharedUserDefaults?.serverTimeDifference ?? 0 + timestamp)
    }
}