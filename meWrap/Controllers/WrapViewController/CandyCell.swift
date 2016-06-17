//
//  CandyCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class CandyCell: EntryStreamReusableView<Candy>, FlowerMenuConstructor {
    
    let imageView = ImageView(backgroundColor: UIColor.whiteColor(), placeholder: ImageView.Placeholder.white.photoStyle(56))
    let commentLabel = Label(preset: .Smaller, textColor: UIColor.whiteColor())
    let videoIndicator = Label(icon: "+", size: 24)
    let gradientView = GradientView(startColor: UIColor.blackColor().colorWithAlphaComponent(0.8))
    private let mediaCommentIndicator = UIImageView()
    private let spinner = specify(UIActivityIndicatorView(activityIndicatorStyle: .White)) {
        $0.color = Color.grayLightest
        $0.hidesWhenStopped = true
    }
    
    private var textCommentConstraint: Constraint!
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        
        if !metrics.disableMenu {
            FlowerMenu.sharedMenu.registerView(self)
        }
        
        let pressedStateButton = Button(type: .Custom)
        pressedStateButton.addTarget(self, action: #selector(self.selectAction), forControlEvents: .TouchUpInside)
        pressedStateButton.highlightedColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        pressedStateButton.normalColor = UIColor.clearColor()
        pressedStateButton.exclusiveTouch = true
        add(imageView) { $0.edges.equalTo(self) }
        add(videoIndicator) {
            $0.top.equalTo(self).offset(2)
            $0.right.equalTo(self).offset(-2)
        }
        add(pressedStateButton) { make in
            make.edges.equalTo(self)
        }
        add(gradientView) { make in
            make.leading.bottom.trailing.equalTo(self)
            make.height.equalTo(36)
        }
        mediaCommentIndicator.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        mediaCommentIndicator.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        commentLabel.textAlignment = .Center
        commentLabel.numberOfLines = 2
        gradientView.add(commentLabel) { make in
            make.trailing.equalTo(gradientView).offset(-4)
            make.centerY.equalTo(gradientView)
            textCommentConstraint = make.leading.equalTo(gradientView).offset(4).constraint
        }
        gradientView.add(mediaCommentIndicator) { make in
            make.centerY.equalTo(gradientView)
            make.leading.equalTo(gradientView).offset(8)
        }
        
        imageView.add(spinner) {
            $0.center.equalTo(imageView)
        }
        imageView.spinner = spinner
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        guard let candy = entry else {
            return
        }
        
        if candy.updateError() == nil && !candy.isVideo {
            
            menu.addEditPhotoAction({
                DownloadingView.downloadCandyImage(candy, success: { (image) -> Void in
                    ImageEditor.editImage(image) { candy.editWithImage($0) }
                    }, failure: { $0?.show() })
            })
            
            menu.addDrawPhotoAction({
                DownloadingView.downloadCandyImage(candy, success: { (image) -> Void in
                    DrawingViewController.draw(image, wrap: candy.wrap) { candy.editWithImage($0) }
                    }, failure: { $0?.show() })
            })
        }
        
        menu.addDownloadAction({
            candy.download({ () -> Void in
                Toast.showDownloadingMediaMessageForCandy(candy)
                }, failure: { $0?.show() })
        })
        
        menu.addShareAction({
            DownloadingView.downloadCandy(candy, message: "downloading_media_for_sharing".ls, success: { [weak self] (url) in
                let activityVC = UIActivityViewController(activityItems: [url, "sharing_text".ls], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = self
                UINavigationController.main.presentViewController(activityVC, animated: true, completion: nil)
                })
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
                let controller = ReportViewController(candy: candy)
                UINavigationController.main.presentViewController(controller, animated: false, completion: nil)
            })
        }
    }
    
    override func didDequeue() {
        super.didDequeue()
        imageView.image = nil
    }
    
    private var uploadingView: UploadingView? {
        didSet {
            if oldValue?.superview == self {
                oldValue?.removeFromSuperview()
            }
            if let uploadingView = uploadingView {
                uploadingView.frame = bounds
                addSubview(uploadingView)
                uploadingView.update()
            }
        }
    }
    
    override func setupEmpty() {
        userInteractionEnabled = true
        exclusiveTouch = true
        uploadingView = nil
        videoIndicator.hidden = true
        imageView.url = nil
        commentLabel.superview?.hidden = true
    }
    
    private weak var videoPlayer: VideoPlayer?
    
    override func willEnqueue() {
        super.willEnqueue()
        videoPlayer?.removeFromSuperview()
    }
    
    static let photoAnimationImage: UIImage? = UIImage.animatedImageNamed("animation_photo_comment_", duration: 3)
    
    static let videoAnimationImage: UIImage? = UIImage.animatedImageNamed("animation_video_comment_", duration: 3)
    
    override func setup(candy: Candy) {
        userInteractionEnabled = true
        exclusiveTouch = true
        videoIndicator.hidden = candy.mediaType != .Video
        imageView.url = candy.asset?.small
        uploadingView = candy.uploadingView
        
        if candy.mediaType == .Video {
            let playerView = VideoPlayer.createPlayerView()
            playerView.frame = imageView.bounds
            playerView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            imageView.insertSubview(playerView, atIndex: 0)
            playerView.url = candy.asset?.videoURL()
            self.videoPlayer = playerView
            self.performSelector(#selector(self.startPlayingVideo), withObject: nil, afterDelay: 0.0)
        }
        
        if let comment = candy.latestComment  {
            let commentType = comment.commentType()
            if commentType == .Text {
                commentLabel.textAlignment = .Center
                textCommentConstraint.updateOffset(4)
                commentLabel.text = comment.text
                gradientView.hidden = comment.text?.isEmpty ?? true
                mediaCommentIndicator.hidden = true
                mediaCommentIndicator.image = nil
            } else  {
                commentLabel.textAlignment = .Left
                mediaCommentIndicator.hidden = false
                textCommentConstraint.updateOffset(36)
                gradientView.hidden = false
                if commentType == .Photo {
                    mediaCommentIndicator.image = CandyCell.photoAnimationImage
                } else {
                    mediaCommentIndicator.image = CandyCell.videoAnimationImage
                }
                mediaCommentIndicator.startAnimating()
                commentLabel.text = comment.displayText()
            }
        } else {
            mediaCommentIndicator.image = nil
            commentLabel.text = nil
            gradientView.hidden = true
        }
    }
    
    func startPlayingVideo() {
        videoPlayer?.playing = true
    }
}