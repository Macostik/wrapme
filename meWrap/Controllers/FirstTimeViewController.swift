//
//  FirstTimeViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 26/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class FirstTimeViewController: WLBaseViewController, WLStillPictureViewControllerDelegate {
    
    func defaultWrap (success: ObjectBlock?, failure: FailureBlock?) {
        if let wrap = Wrap.wrap() {
            wrap.name = String(format:"first_wrap".ls, User.currentUser?.name ?? "")
            wrap.notifyOnAddition()
            Uploader.wrapUploader.upload(Uploading.uploading(wrap)!, success: success, failure: failure)
        }
    }
    
    @IBAction func presentCamera(sender: AnyObject) {
        defaultWrap({ [weak self] wrap -> Void in
            if let stillPictureViewController = WLStillPictureViewController.stillPhotosViewController() {
                stillPictureViewController.wrap = wrap as? Wrap
                stillPictureViewController.mode = .Default
                stillPictureViewController.delegate = self
                self?.presentViewController(stillPictureViewController, animated: true, completion: nil)
            }
            },failure: { [weak self](error) -> Void in
                self?.cancelingIntroduction(nil)
        })
    }
    
    @IBAction func presentBroadcastLive(sender: AnyObject) {
        defaultWrap({ [weak self] wrap -> Void in
            if let addFriendsController = self?.storyboard?["WLAddContributorsViewController"] as? WLAddContributorsViewController {
                addFriendsController.wrap = wrap as? Wrap
                addFriendsController.isBroadcasting = true
                self?.navigationController?.pushViewController(addFriendsController, animated: false)
            }
            },failure: { [weak self](error) -> Void in
                self?.cancelingIntroduction(nil)
            })
    }
    
    @IBAction func cancelingIntroduction(sender: AnyObject?) {
        UIStoryboard.main().present(false)
    }
    
    //MARK: WLStillPictureViewControllerDelegate
    
    func stillPictureViewControllerDidCancel(controller: WLStillPictureViewController) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
}
