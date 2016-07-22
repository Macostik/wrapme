//
//  CallingCenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 5/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import PushKit

final class CallCenter: NSObject, SINCallDelegate, SINManagedPushDelegate {
    
    static let center = CallCenter()
    
    private var _sinch: SINClient?
    var sinch: SINClient? {
        guard let user = User.currentUser else { return nil }
        if let sinch = _sinch where sinch.userId == user.uid {
            return sinch
        } else {
            let sinch = Sinch.clientWithApplicationKey("8d26f7e3-1949-4470-9d5d-48318c3b238d",
                                                       applicationSecret: "G5ezmahHM0+FMwaAjTfXiw==",
                                                       environmentHost: "clientapi.sinch.com",
                                                       userId: user.uid)
            _sinch = sinch
            return sinch
        }
    }
    
    func clear() {
        _sinch = nil
    }
    
    var audioController: SINAudioController? {
        return sinch?.audioController()
    }
    
    var videoController: SINVideoController? {
        return sinch?.videoController()
    }
    
    func call(user: User) {
        guard let sinch = sinch else { return }
        guard let call = sinch.callClient().callUserVideoWithId(user.uid) else { return }
        guard let audioController = sinch.audioController() else { return }
        guard let videoController = sinch.videoController() else { return }
        CallView(user: user, call: call, audioController: audioController, videoController: videoController).present()
    }
    
    var push: SINManagedPush?
    
    func enable() {
        guard let sinch = sinch else { return }
        sinch.delegate = self
        sinch.callClient().delegate = self
        sinch.setSupportCalling(true)
        sinch.setSupportActiveConnectionInBackground(true)
        
        let push = Sinch.managedPushWithAPSEnvironment(.Production)
        push.delegate = self
        push.setDesiredPushTypeAutomatically()
        push.registerUserNotificationSettings()
        self.push = push
        
        sinch.enableManagedPushNotifications()
        
        sinch.start()
        sinch.startListeningOnActiveConnection()
    }
        
    func managedPush(managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [NSObject : AnyObject]!, forType pushType: String!) {
        sinch?.relayRemotePushNotification(payload)
    }
}

extension CallCenter: SINClientDelegate {
    
    func clientDidStart(client: SINClient!) {
        print (">>Sinch is started<<")
    }
    
    func clientDidFail(client: SINClient!, error: NSError!) {
        print (">>self - \(error)<<")
    }
    
    func client(client: SINClient!, logMessage message: String!, area: String!, severity: SINLogSeverity, timestamp: NSDate!) {
        print (">>self - \(message)<<")
    }
}

extension CallCenter: SINCallClientDelegate {
    
    func client(client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        guard let sinch = sinch else { return }
        guard let call = call else { return }
        guard let audioController = sinch.audioController() else { return }
        guard let videoController = sinch.videoController() else { return }
        guard let user = User.entry(call.remoteUserId) else { return }
        user.fetchIfNeeded({ _ in
            CallView(user: user, call: call, audioController: audioController, videoController: videoController).present()
            }) { _ in
        }
    }
    
    func client(client: SINCallClient!, localNotificationForIncomingCall call: SINCall!) -> SINLocalNotification! {
        let notification = SINLocalNotification()
        notification.alertAction = "Answer"
        let name = User.entry(call.remoteUserId)?.name ?? call.remoteUserId ?? ""
        notification.alertBody = String(format: "Incoming call from %@", name)
        
        for i in 1...2 {
            let additionalNotification = UILocalNotification()
            additionalNotification.alertBody = notification.alertBody
            additionalNotification.alertAction = "Answer"
            additionalNotification.userInfo = [
                "callId": call.callId ?? "",
                "isSinchNotification": true,
                "isVideoOfferedKey": true,
                "notificationTypeKey": "incoming",
                "remoteUserId": call.remoteUserId ?? ""
            ]
            additionalNotification.fireDate = NSDate(timeIntervalSinceNow: 2 * NSTimeInterval(i))
            UIApplication.sharedApplication().scheduleLocalNotification(additionalNotification)
        }
        
        return notification
    }
}
