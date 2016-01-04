//
//  FirstTimeViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 26/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class FirstTimeViewController: WLBaseViewController {
    
    private var wrap: Wrap?
    
    private func defaultWrap() -> Wrap? {
        if let wrap = wrap {
            return wrap
        } else if let wrap = Wrap.wrap() {
            wrap.name = String(format:"first_wrap".ls, User.currentUser?.name ?? "")
            wrap.notifyOnAddition()
            self.wrap = wrap
            Uploader.wrapUploader.upload(Uploading.uploading(wrap)!, success: nil, failure: { [weak self] error in
                    if let error = error where !error.isNetworkError {
                        self?.wrap = nil
                        error.show()
                        wrap.remove()
                        self?.cancelingIntroduction(nil)
                    }
            })
            return wrap
        } else {
            return nil
        }
    }
    
    @IBAction func presentCamera(sender: AnyObject) {
        if let wrap = defaultWrap() {
            if let controller = WLStillPictureViewController.stillPhotosViewController() {
                controller.wrap = wrap
                controller.mode = .Default
                controller.delegate = self
                presentViewController(controller, animated: true, completion: nil)
            }
        }
    }
    
    private func presentAddFriends(wrap: Wrap, isBroadcasting: Bool) {
        if let addFriendsController = storyboard?["WLAddContributorsViewController"] as? WLAddContributorsViewController {
            addFriendsController.wrap = wrap
            addFriendsController.isBroadcasting = isBroadcasting
            navigationController?.pushViewController(addFriendsController, animated: false)
        }
    }
    
    @IBAction func presentBroadcastLive(sender: AnyObject) {
        if let wrap = defaultWrap() {
            presentAddFriends(wrap, isBroadcasting: true)
        }
    }
    
    @IBAction func cancelingIntroduction(sender: AnyObject?) {
        Authorization.currentAuthorization.isFirstStepsRepresenting = false
        dismissViewControllerAnimated(false, completion: nil)
        UIStoryboard.main().present(false)
    }
}

extension FirstTimeViewController: WLStillPictureViewControllerDelegate {
    
    func stillPictureViewControllerDidCancel(controller: WLStillPictureViewController) {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    func stillPictureViewController(controller: WLStillPictureViewController!, didFinishWithPictures pictures: [AnyObject]!) {
        dismissViewControllerAnimated(false, completion: nil)
        guard let wrap = wrap else { return }
        SoundPlayer.player.play(.s04)
        if let pictures = pictures as? [MutableAsset] {
            wrap.uploadAssets(pictures)
        }
        presentAddFriends(wrap, isBroadcasting: false)
    }
}
