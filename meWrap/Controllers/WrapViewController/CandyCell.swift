//
//  CandyCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class CandyCell: StreamReusableView {
    
    var imageView = ImageView(backgroundColor: UIColor.whiteColor())
    
    var commentLabel = Label(preset: FontPreset.Smaller, weight: UIFontWeightLight, textColor: UIColor.whiteColor())
    
    var videoIndicator = Label(icon: "+", size: 24)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        imageView.defaultIconSize = 56
        imageView.defaultIconText = "t"
        imageView.defaultIconColor = Color.grayLighter
        addSubview(imageView)
        addSubview(videoIndicator)
        let gradientView = GradientView()
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
    }
    
    override func loadedWithMetrics(metrics: StreamMetrics) {
        super.loadedWithMetrics(metrics)
        guard !metrics.disableMenu else {
            return
        }
        
        FlowerMenu.sharedMenu.registerView(self, constructor: { [weak self] menu -> Void in
            guard let candy = self?.entry as? Candy where !(candy.wrap?.requiresFollowing ?? true) else {
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
                    Toast.showDownloadingMediaMessageForCandy(candy)
                    }, failure: { $0?.show() })
            })
            
            if candy.deletable {
                menu.addDeleteAction({
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
                    if let controller = UIStoryboard.main()["report"] as? ReportViewController {
                        controller.candy = candy
                        UIWindow.mainWindow.rootViewController?.presentViewController(controller, animated: false, completion: nil)
                    }
                })
            }
            })
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