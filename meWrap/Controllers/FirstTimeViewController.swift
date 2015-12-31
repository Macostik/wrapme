//
//  FirstTimeViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 26/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class FirstTimeViewController: WLBaseViewController, WLStillPictureViewControllerDelegate {
    
    private var wrap: Wrap?
    
    func defaultWrap (success: ObjectBlock?, failure: FailureBlock?) {
        if let success = success, let wrap = wrap {
            return success(wrap)
        }
        if let wrap = Wrap.wrap() {
            wrap.name = String(format:"first_wrap".ls, User.currentUser?.name ?? "")
            wrap.notifyOnAddition()
            Uploader.wrapUploader.upload(Uploading.uploading(wrap)!, success: {[weak self] wrap -> Void in
                if let wrap = wrap as? Wrap {
                    self?.wrap = wrap
                    success?(wrap)
                }
            }, failure: failure)
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
            },failure: { [weak self] error -> Void in
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
        self.dismissViewControllerAnimated(false, completion: nil)
        UIStoryboard.main().present(false)
    }
    
    //MARK: WLStillPictureViewControllerDelegate
    
    func stillPictureViewControllerDidCancel(controller: WLStillPictureViewController) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func stillPictureViewController(controller: WLStillPictureViewController!, didFinishWithPictures pictures: [AnyObject]!) {
        guard let wrap = wrap else {
            return
        }
        FollowingViewController.followWrapIfNeeded(wrap) {[weak self] () -> Void in
            SoundPlayer.player.play(.s04)
            if let pictures = pictures as? [MutableAsset] {
                 self?.wrap?.uploadAssets(pictures)
            }
        }
    }
}
