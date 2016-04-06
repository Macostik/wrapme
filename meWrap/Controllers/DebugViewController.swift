//
//  DebugViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 4/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import Photos
import PubNub

class DebugViewController: BaseViewController {
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.whiteColor()
        let closeButton = Button(type: .System)
        closeButton.setTitle("Close", forState: .Normal)
        closeButton.addTarget(self, action: #selector(self.close(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(closeButton)
        closeButton.snp_makeConstraints { (make) in
            make.leading.top.equalTo(view).inset(20)
        }
        
        let addTestUserButton = Button(type: .System)
        addTestUserButton.setTitle("Add Test User", forState: .Normal)
        addTestUserButton.addTarget(self, action: #selector(self.addTestUser(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(addTestUserButton)
        addTestUserButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(view).inset(20)
            make.centerX.equalTo(view)
        }
        
        let addDemoImagesButton = Button(type: .System)
        addDemoImagesButton.setTitle("Add Demo Images", forState: .Normal)
        addDemoImagesButton.addTarget(self, action: #selector(self.addDemoImages(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(addDemoImagesButton)
        addDemoImagesButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(addTestUserButton.snp_top).inset(-20)
            make.centerX.equalTo(view)
        }
        
        let cleanCacheButton = Button(type: .System)
        cleanCacheButton.setTitle("Clean Cache", forState: .Normal)
        cleanCacheButton.addTarget(self, action: #selector(self.cleanCache(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(cleanCacheButton)
        cleanCacheButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(addDemoImagesButton.snp_top).inset(-20)
            make.centerX.equalTo(view)
        }
        
        let showChannelsButton = Button(type: .System)
        showChannelsButton.setTitle("Check channel group", forState: .Normal)
        showChannelsButton.addTarget(self, action: #selector(self.showChannels(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(showChannelsButton)
        showChannelsButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(cleanCacheButton.snp_top).inset(-20)
            make.centerX.equalTo(view)
        }
        
        let resubscribeButton = Button(type: .System)
        resubscribeButton.setTitle("Resubscribe", forState: .Normal)
        resubscribeButton.addTarget(self, action: #selector(self.resubscribe(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(resubscribeButton)
        resubscribeButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(showChannelsButton.snp_top).inset(-20)
            make.centerX.equalTo(view)
        }
        
        let checkAPNSButton = Button(type: .System)
        checkAPNSButton.setTitle("Check APNS", forState: .Normal)
        checkAPNSButton.addTarget(self, action: #selector(self.checkAPNS(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(checkAPNSButton)
        checkAPNSButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(resubscribeButton.snp_top).inset(-20)
            make.centerX.equalTo(view)
        }
    }
    
    @objc private func close(sender: AnyObject) {
        removeFromContainerAnimated(false)
    }
    
    @objc private func checkAPNS(sender: AnyObject) {
        guard let token = NotificationCenter.defaultCenter.pushTokenData else { return }
        PubNub.sharedInstance.pushNotificationEnabledChannelsForDeviceWithPushToken(token) { (result, _) in
            if let channels = result?.data.channels {
                var missedWraps = [String]()
                for wrap in User.currentUser?.wraps ?? [] {
                    if !channels.contains(wrap.uid) {
                        missedWraps.append("\(wrap.name ?? "") : \(wrap.uid ?? "")")
                    }
                }
                UIAlertController.alert("missed APNS:\n\(missedWraps.joinWithSeparator("\n"))").show()
            }
        }
    }
    
    @objc private func resubscribe(sender: AnyObject) {
        let group = "cg-\(User.currentUser?.uid ?? "")"
        PubNub.sharedInstance.unsubscribeFromChannelGroups([group], withPresence: true)
        Dispatch.mainQueue.after(3) {
            PubNub.sharedInstance.subscribeToChannelGroups([group], withPresence: true)
            UIAlertController.alert("resubscribed").show()
        }
    }
    
    @objc private func showChannels(sender: AnyObject) {
        let group = "cg-\(User.currentUser?.uid ?? "")"
        PubNub.sharedInstance.channelsForGroup(group) { (result, _) in
            if let channels = result?.data.channels {
                var missedWraps = [String]()
                for wrap in User.currentUser?.wraps ?? [] {
                    if !channels.contains(wrap.uid) {
                        missedWraps.append("\(wrap.name ?? "") : \(wrap.uid ?? "")")
                    }
                }
                UIAlertController.alert("subscribed: \(PubNub.sharedInstance.isSubscribedOn(group))\nmissed in \(group):\n\(missedWraps.joinWithSeparator("\n"))").show()
            }
        }
    }
    
    @objc private func addTestUser(sender: AnyObject) {
        TestUser.add(completion: { error in
            if let error = error {
                InfoToast.show(error)
            } else {
                InfoToast.show("Current user is added to the list of test users")
            }
        })
    }
    
    @objc private func addDemoImages(sender: UIButton) {
        addDemoImageWithCount(30000)
        InfoToast.show("5 demo images will be added to Photos")
    }
    
    @objc private func cleanCache(sender: UIButton) {
        RunQueue.fetchQueue.cancelAll()
        API.cancelAll()
        let currentUser = User.currentUser
        let context = EntryContext.sharedContext
        for wrap in FetchRequest<Wrap>().execute() {
            context.uncacheEntry(wrap)
            context.deleteObject(wrap)
        }
        for user in FetchRequest<User>().execute() where user != currentUser {
            context.uncacheEntry(user)
            context.deleteObject(user)
        }
        _ = try? context.save()
        
        currentUser?.wraps = []
        ImageCache.defaultCache.clear()
        ImageCache.uploadingCache.clear()
        InMemoryImageCache.instance.removeAllObjects()
        UIStoryboard.main.present(true)
    }
    
    func addDemoImageWithCount(count: Int) {
        Dispatch.defaultQueue.async({ () -> Void in
            guard
                let url = NSURL(string: "https://placeimg.com/\(count % 2 == 0 ? "640/1136" : "1136/640")/any"),
                let data = NSData(contentsOfURL: url),
                let image = UIImage(data: data) else { return }
            for _ in 0...count {
                RunQueue.entryFetchQueue.run { (finish) -> Void in
                    PHPhotoLibrary.addImage(image, success: finish, failure: { _ in finish() })
                }
            }
        })
    }
}
