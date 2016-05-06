//
//  SettingsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class SettingsViewController: BaseViewController, EntryNotifying {
    
    private let avatarView = ImageView(backgroundColor: UIColor.whiteColor())
    
    @IBOutlet weak var accountButton: Button!
    
    override func loadView() {
        super.loadView()
        
        avatarView.defaultIconSize = 16
        avatarView.defaultIconText = "&"
        avatarView.defaultIconColor = UIColor.whiteColor()
        avatarView.defaultBackgroundColor = Color.grayLighter
        avatarView.cornerRadius = 16
        avatarView.borderColor = Color.grayLighter
        avatarView.borderWidth = 1
        view.insertSubview(avatarView, aboveSubview: accountButton)
        avatarView.snp_makeConstraints { (make) in
            make.size.equalTo(32)
            make.leading.equalTo(accountButton).inset(12)
            make.centerY.equalTo(accountButton)
        }
        User.notifier().addReceiver(self)
        
        let debugButton = QAButton(type: .System)
        debugButton.setTitle("Debug", forState: .Normal)
        debugButton.addTarget(self, action: #selector(self.debug(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(debugButton)
        debugButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(view).inset(20)
            make.centerX.equalTo(view)
        }
    }
    
    @objc private func debug(sender: UIButton) {
        addContainedViewController(DebugViewController(), animated: false)
    }
    
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
            API.cancelAll()
            NotificationCenter.defaultCenter.clear()
            NSUserDefaults.standardUserDefaults().clear()
            UIStoryboard.signUp.present(true)
        }).show()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        avatarView.url = User.currentUser?.avatar?.small
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        avatarView.url = User.currentUser?.avatar?.small
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry == User.currentUser
    }
}
