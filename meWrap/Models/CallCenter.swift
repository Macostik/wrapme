//
//  CallingCenter.swift
//  meWrap
//
//  Created by Sergey Maximenko on 5/20/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import PushKit
import CoreTelephony

final class CallCenter: NSObject, SINCallDelegate, SINManagedPushDelegate {
    
    static let center = CallCenter()
    
    static let nativeCenter = CTCallCenter()
    
    private var _sinch: SINClient?
    var sinch: SINClient? {
        guard let user = User.currentUser else { return nil }
        if let sinch = _sinch where sinch.userId == user.uid {
            return sinch
        } else {
            disable()
            _sinch = Sinch.clientWithApplicationKey("8d26f7e3-1949-4470-9d5d-48318c3b238d",
                                                    applicationSecret: "G5ezmahHM0+FMwaAjTfXiw==",
                                                    environmentHost: "clientapi.sinch.com",
                                                    userId: user.uid)
            return _sinch
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
    
    func call(user: User, isVideo: Bool) {
        guard let sinch = sinch else { return }
        guard let call = isVideo ? sinch.callClient().callUserVideoWithId(user.uid) : sinch.callClient().callUserWithId(user.uid) else { return }
        guard let audioController = sinch.audioController() else { return }
        guard let videoController = sinch.videoController() else { return }
        CallViewController(user: user, call: call, isVideo: isVideo, audioController: audioController, videoController: videoController).present()
    }
    
    var push: SINManagedPush?
    
    private func enqueueRestart() {
        Network.network.subscribe(self, block: { [unowned self] (value) in
            if value {
                self.enable()
                Network.network.unsubscribe(self)
            }
            })
    }
    
    func enable() {
        
        if !Network.network.reachable {
            enqueueRestart()
            return
        }
        
        #if DEBUG
            let push = Sinch.managedPushWithAPSEnvironment(.Development)
        #else
            let push = Sinch.managedPushWithAPSEnvironment(.Production)
        #endif
        
        push.delegate = self
        push.setDesiredPushTypeAutomatically()
        self.push = push
        
        guard let sinch = sinch where !sinch.isStarted() else { return }
        sinch.delegate = self
        sinch.callClient()?.delegate = self
        sinch.setSupportCalling(true)
        
        sinch.enableManagedPushNotifications()
        
        sinch.start()
        AudioSession.category = AVAudioSessionCategoryAmbient
    }
    
    func disable() {
        if let sinch = _sinch {
            sinch.unregisterPushNotificationDeviceToken()
            sinch.terminateGracefully()
        }
    }
    
    func managedPush(managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [NSObject : AnyObject]!, forType pushType: String!) {
        sinch?.relayRemotePushNotification(payload)
    }
}

extension CallCenter: SINClientDelegate {
    
    func clientDidStart(client: SINClient!) {}
    
    func clientDidFail(client: SINClient!, error: NSError!) {
        if let error = error where error.isNetworkError {
            enqueueRestart()
        }
    }
    
    func client(client: SINClient!, logMessage message: String!, area: String!, severity: SINLogSeverity, timestamp: NSDate!) {}
}

extension CallCenter: SINCallClientDelegate {
    
    func client(client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        guard let sinch = sinch else { return }
        guard let call = call else { return }
        guard let audioController = sinch.audioController() else { return }
        guard let videoController = sinch.videoController() else { return }
        guard let user = User.entry(call.remoteUserId) where !user.current else { return }
        user.fetchIfNeeded({ _ in
            if let wrap = user.p2pWrap {
                wrap.missedCallDate = NSDate()
                wrap.numberOfMissedCalls = wrap.numberOfMissedCalls + 1
            }
            
            CallViewController(user: user, call: call, isVideo: call.details.videoOffered, audioController: audioController, videoController: videoController).present()
        }) { _ in
        }
    }
    
    func client(client: SINCallClient!, localNotificationForIncomingCall call: SINCall!) -> SINLocalNotification! {
        
        guard let user = User.entry(call.remoteUserId) else { return nil }
        user.p2pWrap?.updateCallDate(NSDate())
        let name = user.name ?? ""
        
        let app = UIApplication.sharedApplication()
        
        guard CallCenter.nativeCenter.currentCalls?.count ?? 0 == 0 else {
            let notification = UILocalNotification()
            notification.alertBody = String(format: "f_is_calling_you".ls, name)
            app.presentLocalNotificationNow(notification)
            return nil
        }
        
        let notification = UILocalNotification()
        notification.alertAction = "answer".ls
        notification.alertBody = String(format: "f_incoming_call_from".ls, name)
        notification.soundName = "incoming.wav"
        notification.userInfo = [
            "callId": call.callId ?? "",
            "isSinchNotification": true,
            "isVideoOfferedKey": true,
            "notificationTypeKey": "incoming",
            "remoteUserId": call.remoteUserId ?? ""
        ]
        
        app.presentLocalNotificationNow(notification)
        let task = app.beginBackgroundTaskWithExpirationHandler(nil)
        Dispatch.mainQueue.after(10) { () in
            app.cancelLocalNotification(notification)
            if call.state != .Ended {
                app.presentLocalNotificationNow(notification)
                Dispatch.mainQueue.after(10) { () in
                    app.cancelLocalNotification(notification)
                    if call.state != .Ended {
                        app.presentLocalNotificationNow(notification)
                    }
                    app.endBackgroundTask(task)
                }
            } else {
                app.endBackgroundTask(task)
            }
        }
        return nil
    }
}
