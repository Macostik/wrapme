//
//  Logger.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import LogEntries

extension UIApplicationState {
    func displayName() -> String {
        switch self {
        case .Active: return "active"
        case .Inactive: return "inactive"
        case .Background: return "in background"
        }
    }
}

class Logger: NSObject {
    private static let leLog: LELog = {
        #if DEBUG
            setenv("XcodeColors", "YES", 0)
        #endif
        let log = LELog.sharedInstance()
        log.token = "e9e259b1-98e6-41b5-b530-d89d1f5af01d"
        return log
    }()
    
    static var remoteLogging: Bool = NSUserDefaults.standardUserDefaults().remoteLogging ?? false
    
    enum LogColor: String {
        case Default = "fg255,255,255;"
        case Yellow = "fg219,219,110;"
        case Green = "fg107,190,31;"
        case Red = "fg201,91,91;"
        case Blue = "fg0,204,204;"
    }
    
    private static let Escape = "\u{001b}["
    
    class func debugLog(string: String, color: LogColor) {
        #if DEBUG
            print("\(Escape)\(color.rawValue)\n\n\(string)\n\(Escape);")
        #endif
    }
    
    class func log(string: String, color: LogColor) {
        #if DEBUG
            print("\(Escape)\(color.rawValue)\n\n\(string)\n\(Escape);")
        #else
            if remoteLogging {
                let appState = UIApplication.sharedApplication().applicationState.displayName()
                let screenName = BaseViewController.lastAppearedScreenName() ?? ""
                leLog.log("\(User.channelName()) (app is \(appState), last visited screen is \(screenName))\n \(string)")
            }
        #endif
    }
    
    class func log(string: String) {
        log(string, color: .Default)
    }
}
