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
    
    @IBOutlet weak var imageView: ImageView!
    
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet weak var videoIndicatorView: UIView!
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        let imageView = ImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        self.imageView = imageView
        let videoIndicatorView = UILabel()
        videoIndicatorView.font = UIFont(name: "icons", size: 24)
        videoIndicatorView.textColor = UIColor.whiteColor()
        videoIndicatorView.text = "+"
        addSubview(videoIndicatorView)
        self.videoIndicatorView = videoIndicatorView
        let gradientView = GradientView()
        gradientView.startColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        gradientView.contentMode = .Bottom
        addSubview(gradientView)
        let commentLabel = Label()
        commentLabel.font = UIFont.lightFontSmaller()
        commentLabel.preset = "smaller"
        commentLabel.textAlignment = .Center
        commentLabel.numberOfLines = 2
        commentLabel.textColor = UIColor.whiteColor()
        gradientView.addSubview(commentLabel)
        self.commentLabel = commentLabel
        
        imageView.snp_makeConstraints(closure: { $0.edges.equalTo(self) })
        
        videoIndicatorView.snp_makeConstraints { $0.top.right.equalTo(self) }

        gradientView.snp_makeConstraints { make in
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }

        commentLabel.snp_makeConstraints { make in
            make.edges.equalTo(gradientView).inset(UIEdgeInsetsMake(4, 4, 4, 4))
        }
    }
    
    override func loadedWithMetrics(metrics: StreamMetrics!) {
        super.loadedWithMetrics(metrics)
        guard !metrics.disableMenu else {
            return
        }
        
        FlowerMenu.sharedMenu().registerView(self, constructor: { [weak self] menu -> Void in
            guard let candy = self?.entry as? Candy where !(candy.wrap?.requiresFollowing ?? true) else {
                return
            }
            
            if candy.updateError() == nil && !candy.isVideo {
                
                menu.addEditPhotoAction({ (_) -> Void in
                    DownloadingView.downloadCandy(candy, success: { (image) -> Void in
                        ImageEditor.editImage(image) { candy.editWithImage($0) }
                        }, failure: { $0?.show() })
                })
                
                menu.addDrawPhotoAction({ (_) -> Void in
                    DownloadingView.downloadCandy(candy, success: { (image) -> Void in
                        WLDrawingViewController.draw(image) { candy.editWithImage($0) }
                        }, failure: { $0?.show() })
                })
            }
            
            menu.addDownloadAction({ (_) -> Void in
                candy.download({ () -> Void in
                    Toast.showDownloadingMediaMessageForCandy(candy)
                    }, failure: { $0?.show() })
            })
            
            if (candy.deletable) {
                menu.addDeleteAction({ (_) -> Void in
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
                menu.addReportAction({ (_) -> Void in
                    if let controller = UIStoryboard.main()["report"] as? ReportViewController {
                        controller.candy = candy
                        UIWindow.mainWindow.rootViewController?.presentViewController(controller, animated: false, completion: nil)
                    }
                })
            }
            
            menu.entry = candy
            })
    }
    
    override func didDequeue() {
        super.didDequeue()
        imageView.image = nil
    }
    
    override func setup(entry: AnyObject!) {
        
        userInteractionEnabled = true
        
        guard let candy = entry as? Candy else {
            videoIndicatorView.hidden = true
            imageView.url = nil
            commentLabel.superview?.hidden = true
            return
        }
        
        videoIndicatorView.hidden = candy.mediaType != .Video;
        commentLabel.text = candy.latestComment?.text
        commentLabel.superview?.hidden = commentLabel.text?.isEmpty ?? true
        
        guard let asset = candy.asset else { return }
        
        if asset.justUploaded {
            StreamView.lock()
            alpha = 0.0
            UIView.animateWithDuration(0.5, animations: {[weak self] () -> Void in
                self?.alpha = 1
                }, completion: { (_) -> Void in
                    asset.justUploaded = false
                    StreamView.unlock()
            })
        }
        
        imageView.url = asset.small
    }
}