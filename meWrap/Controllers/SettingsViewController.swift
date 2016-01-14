//
//  SettingsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Photos

class SettingsViewController: WLBaseViewController {
    
    @IBAction func about(sender: UIButton) {
        let bundle = NSBundle.mainBundle()
        let appName = bundle.displayName ?? ""
        let version = bundle.buildVersion ?? ""
        let build = bundle.buildNumber ?? ""
        let message = String(format:"formatted_about_message".ls, appName, version, build)
        UIAlertController.alert(message).show()
    }
    
    @IBAction func signOut(sender: UIButton) {
        UIAlertController.alert("sign_out".ls, message: "sign_out_confirmation".ls).action("cancel".ls).action("sign_out".ls, handler: { (_) -> Void in
            RunQueue.fetchQueue.cancelAll()
            APIRequest.manager.operationQueue.cancelAllOperations()
            WLNotificationCenter.defaultCenter().clear()
            NSUserDefaults.standardUserDefaults().clear()
            UIStoryboard.signUp().present(true)
            RecentUpdateList.sharedList.updates = nil
        }).show()
    }
    
    @IBAction func addDemoImages(sender: UIButton) {
        addDemoImageWithCount(5)
        Toast.show("5 demo images will be added to Photos")
    }
    
    @IBAction func cleanCache(sender: UIButton) {
        RunQueue.fetchQueue.cancelAll()
        APIRequest.manager.operationQueue.cancelAllOperations()
        let currentUser = User.currentUser
        let context = EntryContext.sharedContext
        for wrap in Wrap.entries() {
            context.uncacheEntry(wrap)
            context.deleteObject(wrap)
        }
        for user in User.entries() where user != currentUser {
            context.uncacheEntry(user)
            context.deleteObject(user)
        }
        _ = try? context.save()
        
        currentUser?.wraps = []
        ImageCache.defaultCache.clear()
        ImageCache.uploadingCache.clear()
        InMemoryImageCache.instance.removeAllObjects()
        UIStoryboard.main().present(true)
    }
    
    func addDemoImageWithCount(count: Int) {
        if (count == 0) {
            return
        }
        
        if let url = NSURL(string: "https://placeimg.com/\(count % 2 == 0 ? "640/1136" : "1136/640")/any") {
            PHPhotoLibrary.addImageAtFileUrl(url, success: { () -> Void in
                self.addDemoImageWithCount(count - 1)
                }, failure: nil)
        }
    }
    
}
