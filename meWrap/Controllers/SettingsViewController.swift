//
//  SettingsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class SettingsViewController: BaseViewController {
    
    override func loadView() {
        super.loadView()
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
            APIRequest.manager.operationQueue.cancelAllOperations()
            NotificationCenter.defaultCenter.clear()
            NSUserDefaults.standardUserDefaults().clear()
            UIStoryboard.signUp.present(true)
            #if DEBUG
                let entries = FetchRequest<Entry>().execute()
                if entries.count > 0 {
                    UIAlertController.alert("Entries: \(entries)").show()
                }
            #endif
        }).show()
    }
}
