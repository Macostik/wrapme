//
//  CandyCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class CandyCell: StreamReusableView, FlowerMenuConstructor {
    
    let imageView = ImageView(backgroundColor: UIColor.whiteColor())
    let commentLabel = Label(preset: FontPreset.Smaller, textColor: UIColor.whiteColor())
    let videoIndicator = Label(icon: "+", size: 24)
    let gradientView = GradientView()
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        
        if !metrics.disableMenu {
            FlowerMenu.sharedMenu.registerView(self)
        }
        
        imageView.defaultIconSize = 56
        imageView.defaultIconText = "t"
        imageView.defaultIconColor = Color.grayLighter
        let pressedStateButton = Button(type: .Custom)
        pressedStateButton.addTarget(self, action: #selector(CandyCell.select as CandyCell -> () -> ()), forControlEvents: .TouchUpInside)
        pressedStateButton.highlightedColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        pressedStateButton.normalColor = UIColor.clearColor()
        pressedStateButton.exclusiveTouch = true
        addSubview(imageView)
        addSubview(videoIndicator)
        addSubview(pressedStateButton)
        gradientView.startColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        gradientView.contentMode = .Bottom
        addSubview(gradientView)
        commentLabel.textAlignment = .Center
        commentLabel.numberOfLines = 2
        gradientView.addSubview(commentLabel)
        
        imageView.snp_makeConstraints(closure: { $0.edges.equalTo(self) })
        
        videoIndicator.snp_makeConstraints {
            $0.top.equalTo(self).offset(2)
            $0.right.equalTo(self).offset(-2)
        }

        gradientView.snp_makeConstraints { make in
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }

        commentLabel.snp_makeConstraints { make in
            make.edges.equalTo(gradientView).inset(UIEdgeInsetsMake(4, 4, 4, 4))
        }
        
        pressedStateButton.snp_makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        guard let candy = entry as? Candy where !(candy.wrap?.requiresFollowing ?? true) else {
            return
        }
        
        if candy.updateError() == nil && !candy.isVideo {
            
            menu.addEditPhotoAction({
                DownloadingView.downloadCandy(candy, success: { (image) -> Void in
                    ImageEditor.editImage(image) { candy.editWithImage($0) }
                    }, failure: { $0?.show() })
            })
            
            menu.addDrawPhotoAction({
                DownloadingView.downloadCandy(candy, success: { (image) -> Void in
                    DrawingViewController.draw(image) { candy.editWithImage($0) }
                    }, failure: { $0?.show() })
            })
        }
        
        menu.addDownloadAction({
            candy.download({ () -> Void in
                InfoToast.showDownloadingMediaMessageForCandy(candy)
                }, failure: { $0?.show() })
        })
        
        if candy.deletable {
            menu.addDeleteAction({ [weak self] in
                UIAlertController.confirmCandyDeleting(candy, success: { (_) -> Void in
                    self?.userInteractionEnabled = false
                    candy.delete({ (_) -> Void in
                        self?.userInteractionEnabled = true
                        }, failure: { (error) -> Void in
                            error?.show()
                            self?.userInteractionEnabled = true
                    })
                    }, failure: nil)
            })
        } else {
            menu.addReportAction({
                if let controller = UIStoryboard.main["report"] as? ReportViewController {
                    controller.candy = candy
                    UIWindow.mainWindow.rootViewController?.presentViewController(controller, animated: false, completion: nil)
                }
            })
        }
    }
    
    override func didDequeue() {
        super.didDequeue()
        imageView.image = nil
    }
    
    override func setup(entry: AnyObject?) {
        
        userInteractionEnabled = true
        exclusiveTouch = true
        
        guard let candy = entry as? Candy else {
            videoIndicator.hidden = true
            imageView.url = nil
            commentLabel.superview?.hidden = true
            return
        }
        
        videoIndicator.hidden = candy.mediaType != .Video
        commentLabel.text = candy.latestComment?.text
        commentLabel.superview?.hidden = commentLabel.text?.isEmpty ?? true
        
        guard let asset = candy.asset else { return }
        
        if asset.justUploaded {
            asset.justUploaded = false
            alpha = 0.0
            UIView.animateWithDuration(0.5, animations: { self.alpha = 1 })
        }
        
        imageView.url = asset.small
    }
}