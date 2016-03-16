//
//  LinkDeviceViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class LinkDeviceViewController: SignupStepViewController {
    
    @IBOutlet weak var passcodeField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func sendPasscode() {
        Authorization.current.signUp().send()
    }
    
    private func linkDevice(success: ObjectBlock, failure: FailureBlock) {
        APIRequest.linkDevice(passcodeField.text!).send({ _ in
            Authorization.current.signIn().send(success, failure: failure)
            }, failure: failure)
    }
    
    @IBAction func next(sender: Button) {
        sender.loading = true
        linkDevice({ [weak self] _ in
            sender.loading = false
            self?.setSuccessStatusAnimated(false)
            }) { (error) -> Void in
                error?.show()
                sender.loading = false
        }
    }
}
