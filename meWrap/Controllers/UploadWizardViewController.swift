//
//  UploadWizardViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 26/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class UploadWizardViewController: WLBaseViewController {
    
    static var isActive = false
    
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
                        self?.navigationController?.popViewControllerAnimated(false)
                    }
            })
            return wrap
        } else {
            return nil
        }
    }
    
    deinit {
        UploadWizardViewController.isActive = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UploadWizardViewController.isActive = true
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
        if let controller = storyboard?["addFriends"] as? WLAddContributorsViewController {
            controller.wrap = wrap
            controller.isBroadcasting = isBroadcasting
            navigationController?.pushViewController(controller, animated: false)
            controller.completionHandler = { [unowned self] _ in
                let storyboard = self.storyboard
                let navigationController = self.navigationController
                var controllers: [UIViewController] = []
                if let controller = navigationController?.viewControllers.first ?? storyboard?["home"] {
                    controllers.append(controller)
                }
                
                if let controller = self.wrap?.viewController() {
                    controllers.append(controller)
                }
                
                self.navigationController?.viewControllers = controllers
                
                if isBroadcasting {
                    if let controller = storyboard?["liveBroadcast"] as? LiveBroadcastViewController {
                        controller.wrap = wrap
                        navigationController?.presentViewController(controller, animated: false, completion: nil)
                    }
                } else {
                    if let controller = storyboard?["uploadWizardEnd"] {
                        navigationController?.presentViewController(controller, animated: false, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func presentBroadcastLive(sender: AnyObject) {
        if let wrap = defaultWrap() {
            presentAddFriends(wrap, isBroadcasting: true)
        }
    }
    
    @IBAction func cancel(sender: AnyObject?) {
        navigationController?.popViewControllerAnimated(false)
    }
}

extension UploadWizardViewController: WLStillPictureViewControllerDelegate {
    
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

class UploadWizardEndViewController: WLBaseViewController {
    @IBAction func close(sender: UIButton) {
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
}
