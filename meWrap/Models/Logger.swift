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
    
    static let logglyDestination = SlimLogglyDestination()
    
    static func configure() {
        Slim.addLogDestination(logglyDestination)
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
    
    static func debugLog(@autoclosure string: () -> String, color: LogColor = .Default, filename: String = #file, line: Int = #line) {
        #if DEBUG
            Slim.debug("\(Escape)\(color.rawValue)\n\(string())\n\n\(Escape);", filename: filename, line: line)
        #endif
    }
    
    static func log<T>(@autoclosure message: () -> T, color: LogColor = .Default, filename: String = #file, line: Int = #line) {
        #if DEBUG
            Slim.debug("\(Escape)\(color.rawValue)\n\(message())\n\n\(Escape);", filename: filename, line: line)
        #else
            if remoteLogging {
                Slim.info(message, filename: filename, line: line)
            }
        #endif
    }
}


