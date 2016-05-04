//
// Created by Mats Melke on 12/02/15.
// Copyright (c) 2015 Baresi. All rights reserved.
//

import Foundation
import UIKit

private let logglyQueue: dispatch_queue_t = dispatch_queue_create(
	"slimlogger.loggly", DISPATCH_QUEUE_SERIAL)

class SlimLogglyDestination: LogDestination {

    var userid:String?
    private var buffer:[String] = [String]()
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var standardFields: [NSObject : AnyObject] = [
        "lang": NSLocale.preferredLanguages()[0],
        "appname": NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as? String ?? "",
        "appversion": NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? String ?? "",
        "devicename": UIDevice.currentDevice().name,
        "devicemodel": UIDevice.currentDevice().model,
        "osversion": UIDevice.currentDevice().systemVersion
    ]

    private var observer: NSObjectProtocol?

    init() {
        observer = NSNotificationCenter.defaultCenter().addObserverForName("UIApplicationWillResignActiveNotification", object: nil, queue: nil, usingBlock: {
            [unowned self] note in
            let tmpbuffer = self.buffer
            self.buffer = [String]()
            self.backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithName("saveLogRecords",
                expirationHandler: {
                    self.endBackgroundTask()
                })
            self.sendLogsInBuffer(tmpbuffer)
        })
    }

    deinit {
        if let observer = observer {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
    private func toJson(dictionary: NSDictionary) -> NSData? {

        var err: NSError?
        do {
            let json = try NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions(rawValue: 0))
            return json
        } catch let error1 as NSError {
            err = error1
            let error = err?.description ?? "nil"
            NSLog("ERROR: Unable to serialize json, error: %@", error)
            return nil
        }
    }

    private func toJsonString(data: NSData) -> String {
        if let jsonstring = NSString(data: data, encoding: NSUTF8StringEncoding) {
            return jsonstring as String
        } else {
            return ""
        }
    }


    func log<T>(@autoclosure message:() -> T, level:LogLevel, filename:String, line:Int) {
        if level.rawValue < SlimLogglyConfig.logglyLogLevel.rawValue {
            // don't log
            return
        }

        var jsonstr = ""
        let mutableDict = NSMutableDictionary(dictionary: standardFields)
        if let msgdict = message() as? [NSObject : AnyObject] {
            mutableDict.addEntriesFromDictionary(msgdict)
        } else {
            mutableDict.setObject("\(message())", forKey: "rawmsg")
        }
        mutableDict.setObject(level.string, forKey: "level")
        mutableDict.setObject(NSDate().timeIntervalSince1970, forKey: "timestamp")
        mutableDict.setObject("\(filename):\(line)", forKey: "sourcelocation")
        mutableDict.setObject(User.uuid(), forKey: "userid")
        mutableDict.setObject(UIApplication.sharedApplication().applicationState.displayName(), forKey: "app_state")
        mutableDict.setObject(BaseViewController.lastAppearedScreenName ?? "", forKey: "last_visited_screen")

        if let jsondata = toJson(mutableDict) {
            jsonstr = toJsonString(jsondata)
        }
        addLogMsgToBuffer(jsonstr)
    }

    private func addLogMsgToBuffer(msg:String) {
        dispatch_async(logglyQueue) {
            self.buffer.append(msg)
            if self.buffer.count > SlimLogglyConfig.maxEntriesInBuffer {
                let tmpbuffer = self.buffer
                self.buffer = [String]()
                self.sendLogsInBuffer(tmpbuffer)
            }
        }
    }

    private func sendLogsInBuffer(stringbuffer:[String]) {
        let allMessagesString = stringbuffer.joinWithSeparator("\n")
        self.traceMessage("LOGGLY: will try to post \(allMessagesString)")
        if let allMessagesData = (allMessagesString as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            let urlRequest = NSMutableURLRequest(URL: NSURL(string: SlimLogglyConfig.logglyUrlString)!)
            urlRequest.HTTPMethod = "POST"
            urlRequest.HTTPBody = allMessagesData
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(urlRequest) { (responsedata: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                if let anError = error {
                    self.traceMessage("Error from Loggly: \(anError)")
                } else if let data = responsedata {
                    self.traceMessage("Posted to Loggly, status = \(NSString(data: data, encoding:NSUTF8StringEncoding))")
                } else {
                    self.traceMessage("Neither error nor responsedata, something's wrong")
                }
                if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                    self.endBackgroundTask()
                }
            }
            task.resume()
        }
    }

    private func endBackgroundTask() {
        if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            print("Ending background task")
        }
    }

    private func traceMessage(msg:String) {
        if SlimConfig.enableConsoleLogging && SlimLogglyConfig.logglyLogLevel == LogLevel.trace {
            print(msg)
        }
    }
}

