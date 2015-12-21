//
//  Logger.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import LogEntries

class Logger: NSObject {
    private static let leLog: LELog = {
        #if DEBUG
            setenv("XcodeColors", "YES", 0)
        #endif
        let log = LELog.sharedInstance()
        log.token = "e9e259b1-98e6-41b5-b530-d89d1f5af01d"
        return log
    }()
    
    static var remoteLogging: Bool?
    
    enum LogColor: String {
        case Default = "fg255,255,255;"
        case Yellow = "fg255,255,0;"
        case Green = "fg0,255,0;"
        case Red = "fg255,0,0;"
    }
    
    private static let Escape = "\u{001b}["
    
    private class func removeLoggingEnabled() -> Bool {
        if let remoteLogging = remoteLogging {
            return remoteLogging
        } else {
            let remoteLogging = NSUserDefaults.standardUserDefaults().remoteLogging ?? false
            self.remoteLogging = remoteLogging
            return remoteLogging
        }
    }
    
    class func log(string: String, color: LogColor) {
        
        #if DEBUG
            print("\(Escape)\(color.rawValue)\n\n\(string)\n\(Escape);")
        #else
            if removeLoggingEnabled() {
                leLog.log("\(User.channelName()) >> \(string)")
            }
        #endif
    }
    
    class func log(string: String) {
        log(string, color: .Default)
    }
}
