//
//  Entry+APIRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/6/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CoreData

private var S3ConfigurationToken: dispatch_once_t = 0

extension Entry {
    
    func recursivelyFetchIfNeeded(success: Block?, failure: FailureBlock?) {
        fetchIfNeeded({ [weak self] (object) -> Void in
            if let container = self?.container {
                container.recursivelyFetchIfNeeded(success, failure: failure)
            } else {
                success?()
            }
            }, failure: failure)
    }
    
    func fetchIfNeeded(success: ObjectBlock?, failure: FailureBlock?) {
        if fetched() {
            success?(self)
        } else {
            RunQueue.entryFetchQueue.run({ [weak self] (finish) -> Void in
                if let entry = self {
                    entry.fetch({ (object) -> Void in
                        finish()
                        success?(object)
                        }, failure: { (error) -> Void in
                            finish()
                            failure?(error)
                    })
                } else {
                    finish()
                    failure?(nil)
                }
                })
        }
    }
    
    func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        success?(self)
    }
    
    func add(success: ObjectBlock?, failure: FailureBlock?) {
        success?(self)
    }
    
    func update(success: ObjectBlock?, failure: FailureBlock?) {
        success?(self)
    }
    
    func delete(success: ObjectBlock?, failure: FailureBlock?) {
        success?(self)
    }
}

extension User {
    override func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        API.user(self).send(success, failure: failure)
    }
    
    func preloadFirstWraps() {
        RunQueue.fetchQueue.run { (finish) -> Void in
            API.wraps(nil).fresh({ [weak self] (wraps) -> Void in
                self?.sortedWraps.prefix(2).all({ $0.preload() })
                finish()
                }, failure: { (_) -> Void in
                    finish()
            })
        }
    }
}

extension Wrap {
    
    func uploadMessage(text: String) {
        let message: Message = Message.contribution()
        let uploading = Uploading.uploading(message)
        message.wrap = self
        message.text = text
        Uploader.messageUploader.upload(uploading)
        message.notifyOnAddition()
    }
    
    func uploadAsset(asset: MutableAsset, createdAt: NSDate) {
        let candy = Candy.candy(asset.type)
        candy.createdAt = createdAt
        candy.updatedAt = createdAt
        candy.wrap = self
        candy.asset = asset.uploadableAsset()
        if let comment = asset.comment where !comment.isEmpty {
            Comment.comment(comment).candy = candy
        }
        Uploader.candyUploader.upload(Uploading.uploading(candy))
        candy.notifyOnAddition()
    }
    
    func uploadAssets(assets: [MutableAsset]) {
        var date = NSDate.now()
        for asset in assets {
            uploadAsset(asset, createdAt: date)
            date = date.dateByAddingTimeInterval(0.5)
        }
    }
    
    override func add(success: ObjectBlock?, failure: FailureBlock?) {
        API.uploadWrap(self).send(success, failure: failure)
    }
    
    override func update(success: ObjectBlock?, failure: FailureBlock?) {
        API.updateWrap(self).send(success, failure: failure)
    }
    
    override func delete(success: ObjectBlock?, failure: FailureBlock?) {
        switch status {
        case .Ready:
            remove()
            success?(nil)
            break
        case .InProgress:
            failure?(NSError(message: "wrap_is_uploading".ls))
            break
        case .Finished:
            if deletable {
                API.deleteWrap(self).send(success, failure: failure)
            } else {
                API.leaveWrap(self).send(success, failure: failure)
            }
            break
        }
    }
    
    override func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        fetch(Wrap.ContentTypeRecent, success: success, failure: failure)
    }
    
    func fetch(contentType: String?, success: ObjectBlock?, failure: FailureBlock?) {
        if uploaded {
            API.wrap(self, contentType: contentType).send(success, failure: failure)
        } else {
            success?(self)
        }
    }
    
    func preload() {
        let history = History(wrap: self)
        history.fresh({ (object) -> Void in
            history.entries.prefix(5).all({
                $0.entries.prefix(20).all({ $0.asset?.fetch() })
            })
            }, failure: nil)
    }
}

extension Uploading {
    
    class func uploading(contribution: Contribution, event: Event = .Add) -> Uploading {
        let uploading = EntryContext.sharedContext.insertEntry(entityName()) as! Uploading
        uploading.type = event.rawValue
        uploading.contribution = contribution
        return uploading
    }
    
    func upload(success: ObjectBlock?, failure: FailureBlock?) {
        if Network.sharedNetwork.reachable {
            if let contribution = contribution where !inProgress {
                inProgress = true
                contribution.notifyOnUpdate(.Default)
                Logger.log("Trying to upload: \(contribution)")
                send(contribution, success: { [weak self] (object) -> Void in
                    self?.inProgress = false
                    self?.remove()
                    success?(object)
                    contribution.notifyOnUpdate(.Default)
                    }, failure: { [weak self] (error) -> Void in
                        self?.inProgress = false
                        if error?.isResponseError(.DuplicatedUploading) ?? false {
                            let keys = [Keys.Candy, Keys.Wrap, Keys.Comment, Keys.Message]
                            if let data = error?.responseData?.objectForPossibleKeys(keys) as? [String : AnyObject] {
                                contribution.map(data)
                            }
                            self?.remove()
                            success?(contribution)
                            contribution.notifyOnUpdate(.Default)
                        } else if error?.isResponseError(.ContentUnavailable) ?? false {
                            contribution.remove()
                            failure?(error)
                        } else {
                            contribution.notifyOnUpdate(.Default)
                            failure?(error)
                        }
                    })
            } else {
                remove()
                failure?(nil)
            }
        } else {
            failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
        }
    }
    
    private func send(contribution: Contribution, success: ObjectBlock?, failure: FailureBlock?) {
        if let type = Event(rawValue: self.type) {
            switch type {
            case .Add: add(contribution, success: success, failure: failure)
            case .Update: update(contribution, success: success, failure: failure)
            case .Delete: failure?(nil)
            }
        } else {
            failure?(nil)
        }
    }
    
    private func add(contribution: Contribution, success: ObjectBlock?, failure: FailureBlock?) {
        if contribution.canBeUploaded {
            contribution.add(success, failure: failure)
        } else {
            Logger.log("Cannot be uploaded: \(contribution)")
            failure?(nil)
        }
    }
    
    private func update(contribution: Contribution, success: ObjectBlock?, failure: FailureBlock?) {
        if contribution.uploaded {
            contribution.update(success, failure: failure)
        } else {
            failure?(nil)
        }
    }
    
    override func remove() {
        super.remove()
        Logger.log("Removing Uploading object for contribution \(contribution ?? "")")
        contribution?.uploading = nil
    }
}

extension Candy {
    
    func enqueueUpdate() -> NSError? {
        let status = statusOfAnyUploadingType()
        if let error = updateError(status) {
            return error
        } else {
            switch (status) {
            case .Ready: break
            case .Finished:
                let uploading = Uploading.uploading(self, event: .Update)
                Uploader.candyUploader.upload(uploading)
                notifyOnUpdate(.Default)
                break
            default:
                break
            }
            return nil
        }
    }
    
    func updateError() -> NSError? {
        return updateError(statusOfAnyUploadingType())
    }
    
    func updateError(status: ContributionStatus) -> NSError? {
        switch status {
        case .InProgress:
            return NSError(message: (isVideo ? "video_is_uploading" : "photo_is_uploading").ls)
        case .Finished:
            if uid == locuid {
                return NSError(message: "publishing_in_progress".ls)
            } else {
                return nil
            }
        default: return nil
        }
    }
    
    func editWithImage(image: UIImage) {
        if valid {
            let asset = MutableAsset(isAvatar: false)
            asset.setImage(image, isDowngrading: false)
            editAsset(asset.uploadableAsset())
            enqueueUpdate()?.show()
        }
    }
    
    func uploadComment(comment: Comment) {
        commentCount += 1
        comment.candy = self
        Uploader.commentUploader.upload(Uploading.uploading(comment))
        comment.notifyOnAddition()
    }
    
    override func add(success: ObjectBlock?, failure: FailureBlock?) {
        
        if !uploaded {
            if let request = API.candyPlaceholder(self) {
                request.send({ _ in
                    self.add(success, failure: failure)
                    }, failure: failure)
            } else {
                failure?(nil)
            }
            return
        }
        
        let metadata = [
            "Accept" : "application/vnd.ravenpod+json;version=\(Environment.current.version)",
            Keys.UID.Device : Authorization.current.deviceUID ?? "",
            Keys.UID.User : contributor?.uid ?? "",
            Keys.UID.Candy : uid,
            Keys.UID.Wrap : wrap?.uid ?? "",
            Keys.UID.Upload : locuid ?? "",
            Keys.ContributedAt : "\(createdAt.timestamp)",
        ]
        
        uploadToS3Bucket(.Candy, metadata: metadata, success: success, failure: failure)
    }
    
    override func update(success: ObjectBlock?, failure: FailureBlock?) {
        
        let metadata = [
            "Accept" : "application/vnd.ravenpod+json;version=\(Environment.current.version)",
            Keys.UID.Device : Authorization.current.deviceUID ?? "",
            Keys.UID.User : User.currentUser?.uid ?? "",
            Keys.UID.Wrap : wrap?.uid ?? "",
            Keys.UID.Candy : uid,
            Keys.EditedAt : "\(updatedAt.timestamp)",
        ]
        
        uploadToS3Bucket(.EditedCandy, metadata: metadata, success: success, failure: failure)
    }
    
    override func delete(success: ObjectBlock?, failure: FailureBlock?) {
        if !uploaded {
            failure?(NSError(message: "publishing_in_progress".ls))
        } else {
            if let request = API.deleteCandy(self) {
                request.send(success, failure: failure)
            } else {
                failure?(nil)
            }
        }
    }
    
    override func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        if uploaded && status == .Finished {
            API.candy(self).send(success, failure: failure)
        } else {
            failure?(NSError(message:(isVideo ? "video_is_uploading" : "photo_is_uploading").ls))
        }
    }
}

extension Message {
    
    override func add(success: ObjectBlock?, failure: FailureBlock?) {
        if let request = API.uploadMessage(self) {
            request.send(success, failure: failure)
        } else {
            failure?(nil)
        }
    }
    
    override func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        if uploaded {
            API.message(self).send(success, failure: failure)
        } else {
            failure?(nil)
        }
    }
}

extension Comment {
    
    override func add(success: ObjectBlock?, failure: FailureBlock?) {
        if let candy = candy, let wrap = candy.wrap where candy.uploaded {
            if let asset = asset where asset.original?.isExistingFilePath == true {
                let metadata = [
                    "Accept" : "application/vnd.ravenpod+json;version=\(Environment.current.version)",
                    Keys.UID.Device : Authorization.current.deviceUID ?? "",
                    Keys.UID.User : contributor?.uid ?? "",
                    Keys.UID.Wrap : candy.wrap?.uid ?? "",
                    Keys.UID.Candy : candy.uid ?? "",
                    Keys.UID.Upload : locuid ?? "",
                    Keys.ContributedAt : "\(createdAt.timestamp)",
                ]
                uploadToS3Bucket(.Comment, metadata: metadata, success: success, failure: failure)
            } else {
                API.postComment(self, candy: candy, wrap: wrap).send(success, failure: failure)
            }
        } else {
            failure?(nil)
        }
    }
    
    override func delete(success: ObjectBlock?, failure: FailureBlock?) {
        if let candy = candy, let wrap = candy.wrap {
            if !uploaded {
                failure?(NSError(message: "publishing_in_progress".ls))
            } else {
                API.deleteComment(self, candy: candy, wrap: wrap).send(success, failure: failure)
            }
        } else {
            remove()
            success?(nil)
        }
    }
    
    override func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        if uploaded {
            API.comment(self).send(success, failure: failure)
        } else {
            failure?(NSError(message:("comment_is_uploading").ls))
        }
    }
}
