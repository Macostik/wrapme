//
//  FirstTimeViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 26/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class FirstTimeViewController: WLBaseViewController {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func createDefaultWrap() {
        if let wrap = Wrap.wrap() {
            wrap.name = String(format:"first_wrap".ls, User.currentUser?.name ?? "")
            wrap.notifyOnAddition()
            Uploader.wrapUploader.upload(Uploading.uploading(wrap)!, success:nil, failure: nil);
        }
    }
}