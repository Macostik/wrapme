//
//  Logger.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIApplicationState {
    func displayName() -> String {
        switch self {
        case .Active: return "active"
        case .Inactive: return "inactive"
        case .Background: return "in background"
        }
    }
}

struct Logger {
    
    static func configure() {
        Slim.addLogDestination(SlimLogglyDestination())
    }
    
    static var remoteLogging: Bool = NSUserDefaults.standardUserDefaults().remoteLogging ?? false
    
    enum LogColor: String {
        case Default = "fg255,255,255;"
        case Yellow = "fg219,219,110;"
        case Green = "fg107,190,31;"
        case Red = "fg201,91,91;"
        case Blue = "fg0,204,204;"
    }
    
    private static let Escape = "\u{001b}["
    
    static func debugLog(string: String, color: LogColor = .Default, filename: String = __FILE__, line: Int = __LINE__) {
        #if DEBUG
            Slim.debug("\(Escape)\(color.rawValue)\n\(string)\n\n\(Escape);", filename: filename, line: line)
        #endif
    }
    
    static func log(string: String, color: LogColor = .Default, filename: String = __FILE__, line: Int = __LINE__) {
        #if DEBUG
            Slim.debug("\(Escape)\(color.rawValue)\n\(string)\n\n\(Escape);", filename: filename, line: line)
        #else
            if remoteLogging {
                let appState = UIApplication.sharedApplication().applicationState.displayName()
                let screenName = BaseViewController.lastAppearedScreenName ?? ""
                let log = "{\"uuid\":\(User.uuid()),\"app_state\":\(appState),\"last_visited_screen\":\(screenName),\"message\":\(string)}"
                Slim.info(log)
            }
        #endif
    }
}


