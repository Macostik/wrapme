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
    let closeButton = Button(icon: "V", size: 20, textColor: .whiteColor())
    
    private func mask(isTop: Bool) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let radius: CGFloat = 6
        let maxX = ScreenSize.width - 32
        let maxY = ScreenSize.height/2 - 80
        let pi = CGFloat(M_PI)
        let path = UIBezierPath()
        path.addArcWithCenter((radius) ^ (radius), radius: radius, startAngle: pi, endAngle: pi * 1.5, clockwise: true)
        if isTop {
            path.line((maxX - radius) ^ 0)
        } else {
            path.line((maxX/2 - 16) ^ 0)
            path.addArcWithCenter(maxX/2 ^ -4, radius: 16, startAngle: pi, endAngle: 0, clockwise: false)
            path.line((maxX - radius) ^ 0)
        }
        path.addArcWithCenter((maxX - radius) ^ radius, radius: radius, startAngle: pi * 1.5, endAngle: 0, clockwise: true)
        path.line(maxX ^ (maxY - radius))
        path.addArcWithCenter((maxX - radius) ^ (maxY - radius), radius: radius, startAngle: 0, endAngle: pi * 0.5, clockwise: true)
        if isTop {
            path.line((maxX/2 + 16) ^ maxY)
            path.addArcWithCenter(maxX/2 ^ (maxY + 4), radius: 16, startAngle: 0, endAngle: pi, clockwise: false)
            path.line((radius) ^ maxY)
        } else {
            path.line((radius) ^ maxY)
        }
        path.addArcWithCenter((radius) ^ (maxY - radius), radius: radius, startAngle: pi * 0.5, endAngle: pi, clockwise: true)
        path.closePath()
        layer.path = path.CGPath
        return layer
    }
    
    override func loadView() {
        super.loadView()
        
        let p2pBackgroundImage = UIImage(named: "p2p_background")
        let backgroundImageView = UIImageView(image: p2pBackgroundImage)
        backgroundImageView.contentMode = .ScaleAspectFill
        
        view.add(backgroundImageView) { $0.edges.equalTo(view) }
        view.add(UIVisualEffectView(effect: UIBlurEffect(style: .Dark))) { $0.edges.equalTo(view) }
        
        view.add(closeButton) { (make) in
            make.top.equalTo(view).offset(32)
            make.trailing.equalTo(view).offset(-16)
        }
        
        let title = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        title.text = "create_new_wrap".ls
        view.add(title) { (make) in
            make.centerY.equalTo(closeButton)
            make.leading.equalTo(view).offset(16)
            make.trailing.lessThanOrEqualTo(closeButton.snp_leading).offset(-12)
        }
        
        let p2pView = UIView()
        p2pView.layer.mask = mask(true)
        p2pView.backgroundColor = Color.orange
        view.add(p2pView) { (make) in
            make.height.equalTo(view).multipliedBy(0.5).offset(-80)
            make.leading.equalTo(view).offset(16)
            make.trailing.equalTo(view).offset(-16)
            make.bottom.equalTo(view.snp_centerY).offset(6)
        }
        let p2pBackground = UIImageView(image: p2pBackgroundImage)
        p2pBackground.contentMode = .ScaleAspectFill
        p2pBackground.clipsToBounds = true
        p2pView.add(p2pBackground) { (make) in
            make.leading.top.trailing.equalTo(p2pView)
        }
        p2pButton.highlightedColor = Color.grayDarker.colorWithAlphaComponent(0.75)
        p2pView.add(p2pButton) { (make) in
            make.edges.equalTo(p2pView)
        }
        let p2pLabel = Label(preset: .Normal, weight: .Bold, textColor: UIColor.whiteColor())
        p2pLabel.highlightedTextColor = Color.grayLighter
        p2pLabel.text = "p2p_wrap".ls
        p2pView.add(p2pLabel) { (make) in
            make.top.equalTo(p2pBackground.snp_bottom)
            make.centerX.bottom.equalTo(p2pView)
            make.height.equalTo(50)
        }
        p2pButton.highlightings = [p2pLabel]
        
        let groupView = UIView()
        groupView.layer.mask = mask(false)
        groupView.backgroundColor = Color.orange
        view.add(groupView) { (make) in
            make.height.equalTo(view).multipliedBy(0.5).offset(-80)
            make.top.equalTo(view.snp_centerY).offset(14)
            make.leading.equalTo(view).offset(16)
            make.trailing.equalTo(view).offset(-16)
        }
        let groupBackground = UIImageView(image: UIImage(named: "group_background"))
        groupBackground.clipsToBounds = true
        groupBackground.contentMode = .ScaleAspectFill
        groupView.add(groupBackground) { (make) in
            make.leading.bottom.trailing.equalTo(groupView)
        }
        groupButton.highlightedColor = Color.grayDarker.colorWithAlphaComponent(0.75)
        groupView.add(groupButton) { (make) in
            make.edges.equalTo(groupView)
        }
        
        let groupLabel = Label(preset: .Normal, weight: .Bold, textColor: UIColor.whiteColor())
        groupLabel.highlightedTextColor = Color.grayLighter
        groupLabel.text = "group_wrap".ls
        groupView.add(groupLabel) { (make) in
            make.bottom.equalTo(groupBackground.snp_top)
            make.centerX.top.equalTo(groupView)
            make.height.equalTo(50)
        }
        groupButton.highlightings = [groupLabel]
        
        let orLabel = Label(preset: .Smaller, weight: .Bold, textColor: Color.orange)
        orLabel.text = "or".ls
        view.add(orLabel) { (make) in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view).offset(10)
        }
        
        groupButton.addTarget(self, touchUpInside: #selector(self.createGroupWrap(_:)))
        p2pButton.addTarget(self, touchUpInside: #selector(self.createP2PWrap(_:)))
        closeButton.addTarget(self, touchUpInside: #selector(self.close(_:)))
    }
    
    @objc private func createP2PWrap(sender: AnyObject) {
        addFriends(nil, backgroundImage: UIImage(named: "p2p_background"))
    }
    
    private func addFriends(name: String?, backgroundImage: UIImage?) {
        let controller = AddFriendsViewController(wrap: nil)
        controller.backgroundImageView.image = backgroundImage
        controller.p2p = name == nil
        controller.completionBlock = { [unowned controller, weak self] existingWrap in
            
            if let wrap = existingWrap {
                let nc = UINavigationController.main
                let controller = wrap.createViewController() as! WrapViewController
                nc.viewControllers = nc.viewControllers.prefix(1) + [controller]
            } else {
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
        }
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @objc private func createGroupWrap(sender: AnyObject) {
        let controller = WrapNameViewController()
        controller.backgroundImageView.image = UIImage(named: "group_background")
        controller.completionHandler = { [weak self] name in
            self?.addFriends(name, backgroundImage: controller.backgroundImageView.image)
        }
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @objc private func close(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(false)
    }
}
