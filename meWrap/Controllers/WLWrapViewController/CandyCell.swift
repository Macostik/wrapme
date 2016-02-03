//
//  CandyCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class CandyCell: StreamReusableView {
    
    @IBOutlet weak var imageView: ImageView!
    
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet weak var videoIndicatorView: UIView!
    
    override func loadedWithMetrics(metrics: StreamMetrics!) {
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
                        }, failure: { (error) -> Void in
                            error?.show()
                    })
                })
                
                menu.addDrawPhotoAction({ (_) -> Void in
                    DownloadingView.downloadCandy(candy, success: { (image) -> Void in
                        WLDrawingViewController.draw(image) { candy.editWithImage($0) }
                        }, failure: { (error) -> Void in
                            error?.show()
                    })
                })
            }
            
            menu.addDownloadAction({ (_) -> Void in
                candy.download({ () -> Void in
                    Toast.showDownloadingMediaMessageForCandy(candy)
                    }, failure: { (error) -> Void in
                        error?.show()
                })
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