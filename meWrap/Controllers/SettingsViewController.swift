//
//  SettingsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import Photos

class SettingsViewController: BaseViewController {
    
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
            NotificationCenter.defaultCenter.clear()
            NSUserDefaults.standardUserDefaults().clear()
            UIStoryboard.signUp.present(true)
        }).show()
    }
    
    @IBAction func addTestUser(sender: AnyObject) {
        TestUser.add(completion: { error in
            if let error = error {
                Toast.show(error)
            } else {
                Toast.show("Current user is added to the list of test users")
            }
        })
    }
    
    @IBAction func addDemoImages(sender: UIButton) {
        addDemoImageWithCount(30000)
        Toast.show("5 demo images will be added to Photos")
    }
    
    @IBAction func cleanCache(sender: UIButton) {
        RunQueue.fetchQueue.cancelAll()
        APIRequest.manager.operationQueue.cancelAllOperations()
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
