//
//  SettingsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class SettingsViewController: BaseViewController, EntryNotifying {
    
    private let avatarView = ImageView(backgroundColor: UIColor.whiteColor(), placeholder: ImageView.Placeholder.gray.userStyle(16))
    
    private let accountButton = Button(preset: .Large, weight: .Regular, textColor: Color.grayDark)
    private let aboutButton = Button(preset: .Large, weight: .Regular, textColor: Color.grayDark)
    private let signOutButton = Button(preset: .Large, weight: .Regular, textColor: Color.grayDark)
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .whiteColor()
        
        let navigationBar = UIView()
        
        view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        
        navigationBar.backgroundColor = Color.orange
        navigationBar.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        let title = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        title.text = "settings".ls
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        
        self.navigationBar = navigationBar
        
        view.add(accountButton) { (make) in
            make.top.equalTo(navigationBar.snp_bottom)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(44)
        }
        
        avatarView.cornerRadius = 16
        avatarView.setBorder(color: Color.grayLighter)
        view.add(avatarView) { (make) in
            make.size.equalTo(32)
            make.leading.equalTo(accountButton).inset(12)
            make.centerY.equalTo(accountButton)
        }
        
        var separator = SeparatorView(color: Color.grayLightest, contentMode: .Top)
        view.add(separator) { (make) in
            make.top.equalTo(accountButton.snp_bottom)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(1)
        }
        
        view.add(aboutButton) { (make) in
            make.top.equalTo(separator.snp_bottom)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(44)
        }
        
        let aboutIcon = Label(icon: "a", size: 32, textColor: Color.orange)
        view.add(aboutIcon) { (make) in
            make.size.equalTo(32)
            make.leading.equalTo(aboutButton).offset(12)
            make.centerY.equalTo(aboutButton)
        }
        
        separator = SeparatorView(color: Color.grayLightest, contentMode: .Top)
        view.add(separator) { (make) in
            make.top.equalTo(aboutButton.snp_bottom)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(1)
        }
        
        view.add(signOutButton) { (make) in
            make.top.equalTo(separator.snp_bottom)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(44)
        }
        
        let signOutIcon = Label(icon: "(", size: 32, textColor: Color.orange)
        view.add(signOutIcon) { (make) in
            make.size.equalTo(32)
            make.leading.equalTo(signOutButton).offset(12)
            make.centerY.equalTo(signOutButton)
        }
        
        separator = SeparatorView(color: Color.grayLightest, contentMode: .Top)
        view.add(separator) { (make) in
            make.top.equalTo(signOutButton.snp_bottom)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(1)
        }
        
        accountButton.addTarget(self, touchUpInside: #selector(self.account(_:)))
        accountButton.setTitle("account".ls, forState: .Normal)
        accountButton.contentHorizontalAlignment = .Left
        accountButton.titleEdgeInsets.left = 56
        accountButton.highlightedColor = Color.grayLightest
        
        aboutButton.addTarget(self, touchUpInside: #selector(self.about(_:)))
        aboutButton.setTitle("about_app".ls, forState: .Normal)
        aboutButton.contentHorizontalAlignment = .Left
        aboutButton.titleEdgeInsets.left = 56
        aboutButton.highlightedColor = Color.grayLightest
        
        signOutButton.addTarget(self, touchUpInside: #selector(self.signOut(_:)))
        signOutButton.setTitle("sign_out".ls, forState: .Normal)
        signOutButton.contentHorizontalAlignment = .Left
        signOutButton.titleEdgeInsets.left = 56
        signOutButton.highlightedColor = Color.grayLightest
        
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
    
    @IBAction func account(sender: AnyObject) {
        navigationController?.pushViewController(ChangeProfileViewController(), animated: false)
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
            CallCenter.center.disable()
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
