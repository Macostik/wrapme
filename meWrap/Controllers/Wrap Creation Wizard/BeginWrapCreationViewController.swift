//
//  UploadWizardViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 26/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

final class BeginWrapCreationViewController: BaseViewController {
    
    let p2pButton = Button(type: .Custom)
    let groupButton = Button(type: .Custom)
    let closeButton = Button(icon: "!", size: 15, textColor: Color.orange)
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = Color.grayDarker
        
        view.add(closeButton) { (make) in
            make.top.equalTo(view).offset(32)
            make.trailing.equalTo(view).offset(-12)
        }
        
        let title = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        title.text = "create_new_wrap".ls
        view.add(title) { (make) in
            make.centerY.equalTo(closeButton)
            make.leading.equalTo(view).offset(12)
            make.trailing.lessThanOrEqualTo(closeButton.snp_leading).offset(-12)
        }
        
        let p2pView = UIView()
        p2pView.cornerRadius = 6
        p2pView.clipsToBounds = true
        p2pView.backgroundColor = Color.orange
        view.add(p2pView) { (make) in
            make.top.equalTo(closeButton.snp_bottom).offset(12)
            make.leading.equalTo(view).offset(12)
            make.trailing.equalTo(view).offset(-12)
        }
        let p2pBackground = UIImageView(image: UIImage(named: "create_wrap_step_first"))
        p2pBackground.contentMode = .ScaleAspectFill
        p2pView.add(p2pBackground) { (make) in
            make.leading.top.trailing.equalTo(p2pView)
            make.bottom.equalTo(p2pView).offset(-50)
        }
        p2pButton.highlightedColor = Color.grayDarker.colorWithAlphaComponent(0.75)
        p2pView.add(p2pButton) { (make) in
            make.edges.equalTo(p2pView)
        }
        let p2pLabel = Label(preset: .Normal, weight: .Bold, textColor: UIColor.whiteColor())
        p2pLabel.highlightedTextColor = Color.grayLighter
        p2pLabel.text = "p2p_wrap".ls
        p2pView.add(p2pLabel) { (make) in
            make.centerX.equalTo(p2pView)
            make.centerY.equalTo(p2pView.snp_bottom).offset(-25)
        }
        p2pButton.highlightings = [p2pLabel]
        
        let groupView = UIView()
        groupView.cornerRadius = 6
        groupView.clipsToBounds = true
        groupView.backgroundColor = Color.orange
        view.add(groupView) { (make) in
            make.height.equalTo(p2pView)
            make.top.equalTo(p2pView.snp_bottom).offset(12)
            make.leading.equalTo(view).offset(12)
            make.trailing.bottom.equalTo(view).offset(-12)
        }
        let groupBackground = UIImageView(image: UIImage(named: "create_wrap_step_last"))
        groupBackground.contentMode = .ScaleAspectFill
        groupView.add(groupBackground) { (make) in
            make.leading.bottom.trailing.equalTo(groupView)
            make.top.equalTo(groupView).offset(50)
        }
        groupButton.highlightedColor = Color.grayDarker.colorWithAlphaComponent(0.75)
        groupView.add(groupButton) { (make) in
            make.edges.equalTo(groupView)
        }
        
        let groupLabel = Label(preset: .Normal, weight: .Bold, textColor: UIColor.whiteColor())
        groupLabel.highlightedTextColor = Color.grayLighter
        groupLabel.text = "group_wrap".ls
        groupView.add(groupLabel) { (make) in
            make.centerX.equalTo(groupView)
            make.centerY.equalTo(groupView.snp_top).offset(25)
        }
        groupButton.highlightings = [groupLabel]
        
        let orLabel = Label(preset: .Smaller, weight: .Bold, textColor: Color.orange)
        orLabel.text = "or".ls
        orLabel.cornerRadius = 16
        orLabel.clipsToBounds = true
        orLabel.textAlignment = .Center
        orLabel.backgroundColor = view.backgroundColor
        view.add(orLabel) { (make) in
            make.centerX.equalTo(view)
            make.centerY.equalTo(p2pView.snp_bottom).offset(6)
            make.size.equalTo(32)
        }
        
        groupButton.addTarget(self, touchUpInside: #selector(self.createGroupWrap(_:)))
        p2pButton.addTarget(self, touchUpInside: #selector(self.createP2PWrap(_:)))
        closeButton.addTarget(self, touchUpInside: #selector(self.close(_:)))
    }
    
    @objc private func createP2PWrap(sender: AnyObject) {
        addFriends(nil, backgroundImage: UIImage(named: "create_wrap_step_first"))
    }
    
    private func addFriends(name: String?, backgroundImage: UIImage?) {
        let controller = AddFriendsViewController(wrap: nil)
        controller.backgroundImageView.image = backgroundImage
        controller.p2p = name == nil
        controller.completionHandler = { [unowned controller, weak self] _ in
            let wrap = insertWrap()
            let invitees = controller.getInvitees(wrap)
            wrap.name = name ?? invitees.first?.name
            wrap.p2p = controller.p2p
            let completeController = NewWrapCreatedViewController()
            completeController.backgroundImageView.image = backgroundImage
            completeController.wrap = wrap
            completeController.p2p = controller.p2p
            self?.navigationController?.pushViewController(completeController, animated: false)
            
            Uploader.wrapUploader.upload(Uploading.uploading(wrap), success: nil, failure: { error in
                if let error = error where !error.isNetworkError {
                    error.show()
                    wrap.remove()
                    self?.navigationController?.popViewControllerAnimated(false)
                }
            })
        }
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @objc private func createGroupWrap(sender: AnyObject) {
        let controller = WrapNameViewController()
        controller.backgroundImageView.image = UIImage(named: "create_wrap_step_last")
        controller.completionHandler = { [weak self] name in
            self?.addFriends(name, backgroundImage: controller.backgroundImageView.image)
        }
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @objc private func close(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(false)
    }
}
