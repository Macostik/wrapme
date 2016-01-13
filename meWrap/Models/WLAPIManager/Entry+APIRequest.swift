//
//  Entry+APIRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/6/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CoreData
import AWSS3

private var S3ConfigurationToken: dispatch_once_t = 0

extension Entry {
    
    func recursivelyFetchIfNeeded(success: Block?, failure: FailureBlock?) {
        if recursivelyFetched() {
            success?()
        } else {
            fetchIfNeeded({ [weak self] (object) -> Void in
                if let container = self?.container {
                    container.recursivelyFetchIfNeeded(success, failure: failure)
                } else {
                    success?()
                }
                }, failure: failure)
        }
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
        if let request = APIRequest.user(self) {
            request.send(success, failure: failure)
        } else {
            failure?(nil)
        }
    }
    
    func preloadFirstWraps() {
        RunQueue.fetchQueue.run { (finish) -> Void in
            PaginatedRequest.wraps(nil).fresh({ [weak self] (wraps) -> Void in
                
                if let wraps = self?.sortedWraps {
                    for (index, wrap) in wraps.enumerate() {
                        wrap.preload()
                        if index == 2 {
                            break
                        }
                    }
                }
                
                finish()
                }, failure: { (_) -> Void in
                    finish()
            })
        }
    }
}

extension Device {
    
}

extension Contribution {
    
}

extension Wrap {
    
    func uploadMessage(text: String) {
        let message = Message.contribution()
        let uploading = Uploading.uploading(message)
        message.wrap = self
        message.text = text
        message.notifyOnAddition()
        Uploader.messageUploader.upload(uploading)
    }
    
    func uploadAsset(asset: MutableAsset) {
        let candy = Candy.candy(asset.type)
        let uploading = Uploading.uploading(candy)
        candy.wrap = self
        candy.asset = asset.uploadablePicture(true)
        if let comment = asset.comment where !comment.isEmpty {
            Comment.comment(comment).candy = candy
        }
        candy.notifyOnAddition()
        Uploader.candyUploader.upload(uploading)
    }
    
    func uploadAssets(assets: [MutableAsset]) {
        for asset in assets {
            RunQueue.uploadCandiesQueue.run({ [weak self] (finish) -> Void in
                self?.uploadAsset(asset)
                Dispatch.mainQueue.after(0.6, block: finish)
            })
        }
    }
    
    override func add(success: ObjectBlock?, failure: FailureBlock?) {
        APIRequest.uploadWrap(self).send(success, failure: failure)
    }
    
    override func update(success: ObjectBlock?, failure: FailureBlock?) {
        APIRequest.updateWrap(self).send(success, failure: failure)
    }
    
    override func delete(success: ObjectBlock?, failure: FailureBlock?) {
        if deletable {
            
        } else {
            APIRequest.leaveWrap(self).send(success, failure: failure)
        }
        switch status {
        case .Ready:
            remove()
            success?(nil)
            break
        case .InProgress:
            failure?(NSError(message: "wrap_is_uploading".ls))
            break
        case .Finished:
            APIRequest.deleteWrap(self).send(success, failure: failure)
            break
        }
    }
    
    override func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        fetch(Wrap.ContentTypeRecent, success: success, failure: failure)
    }
    
    func fetch(contentType: String?, success: ObjectBlock?, failure: FailureBlock?) {
        if uploaded {
            APIRequest.wrap(self, contentType: contentType).send(success, failure: failure)
        } else {
            success?(self)
        }
    }
    
    func preload() {
        let history = History(wrap: self)
        history.fresh({ (object) -> Void in
            for (index, entry) in history.entries.enumerate() {
                if let item = entry as? HistoryItem {
                    for (index, candy) in item.candies.enumerate() {
                        candy.asset?.fetch(nil)
                        if index == 20 {
                            break
                        }
                    }
                }
                if index == 5 {
                    break
                }
            }
            }, failure: nil)
    }
}

extension Uploading {
    
    class func uploading(contribution: Contribution) -> Uploading {
        return uploading(contribution, event: .Add)
    }
    
    class func uploading(contribution: Contribution, event: Event) -> Uploading {
        let uploading = EntryContext.sharedContext.insertEntry(entityName()) as! Uploading
        uploading.type = event.rawValue
        uploading.contribution = contribution
        return uploading
    }
    
    func upload(success: ObjectBlock?, failure: FailureBlock?) {
        if Network.sharedNetwork.reachable {
            if let contribution = contribution {
                sendTypedRequest({ [weak self] (object) -> Void in
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
                inProgress = true
                contribution.notifyOnUpdate(.Default)
            } else {
                remove()
                failure?(nil)
            }
        } else {
            failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
        }
    }

    func sendTypedRequest(success: ObjectBlock?, failure: FailureBlock?) {
        if let type = Event(rawValue: self.type) {
            switch type {
            case .Add:
                add(success, failure: failure)
                break
            case .Update:
                update(success, failure: failure)
                break
            case .Delete:
                break
            }
        }
    }
    
    override func add(success: ObjectBlock?, failure: FailureBlock?) {
        if let contribution = contribution {
            if contribution.canBeUploaded || contribution.status == .Ready {
                contribution.add(success, failure: failure)
            } else {
                failure?(nil)
            }
        }
    }
    
    override func update(success: ObjectBlock?, failure: FailureBlock?) {
        if let contribution = contribution {
            if contribution.uploaded && contribution.statusOfUploadingEvent(.Update) == .Ready {
                contribution.update(success, failure: failure)
            } else {
                failure?(nil)
            }
        }
    }
    
    override func remove() {
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
            let asset = MutableAsset()
            asset.setImage(image)
            editAsset(asset.uploadablePicture(false))
            enqueueUpdate()?.show()
        }
    }
    
    func uploadComment(text: String) {
        let comment = Comment.comment(text)
        let uploading = Uploading.uploading(comment)
        commentCount++
        comment.candy = self
        comment.notifyOnAddition()
        Dispatch.mainQueue.after(0.3, block: { Uploader.commentUploader.upload(uploading) })
    }

    override func add(success: ObjectBlock?, failure: FailureBlock?) {

        var metadata = [
            "Accept" : "application/vnd.ravenpod+json;version=\(Environment.currentEnvironment.version)",
            Keys.UID.Device : Authorization.currentAuthorization.deviceUID ?? "",
            Keys.UID.User : contributor?.uid ?? "",
            Keys.UID.Wrap : wrap?.uid ?? "",
            Keys.UID.Upload : locuid ?? "",
            Keys.ContributedAt : "\(createdAt.timestamp)"
        ]
        
        if let comment = comments?.filter({ $0.uploading == nil }).first  {
            if let text = comment.text, let locuid = comment.locuid {
                var escapedText = ""
                for unicodeScalar in text.unicodeScalars {
                    escapedText += unicodeScalar.escape(asASCII: true)
                }
                metadata["message"] = escapedText
                metadata["message_upload_uid"] = locuid
            }
        }
        
        uploadToS3Bucket(metadata, success: success, failure: failure)
    }
    
    override func update(success: ObjectBlock?, failure: FailureBlock?) {
        
        let metadata = [
            "Accept" : "application/vnd.ravenpod+json;version=\(Environment.currentEnvironment.version)",
            Keys.UID.Device : Authorization.currentAuthorization.deviceUID ?? "",
            Keys.UID.User : User.currentUser?.uid ?? "",
            Keys.UID.Wrap : wrap?.uid ?? "",
            Keys.UID.Candy : uid,
            Keys.EditedAt : "\(updatedAt.timestamp)"
        ]
        
        uploadToS3Bucket(metadata, success: success, failure: failure)
    }
    
    func uploadToS3Bucket(metadata: [String:String], success: ObjectBlock?, failure: FailureBlock?) {
        
        dispatch_once(&S3ConfigurationToken) {
            let accessKey = "AKIAIPEMEBV7F4GN2FVA"
            let secretKey = "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"
            let credentialsProvider = AWSStaticCredentialsProvider(accessKey:accessKey, secretKey:secretKey)
            let configuration = AWSServiceConfiguration(region:.USWest2, credentialsProvider:credentialsProvider)
            AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        }
        
        guard let original = asset?.original else {
            remove()
            failure?(NSError(code: ResponseCode.UploadFileNotFound.rawValue))
            return
        }
        
        let path = original as NSString
        
        if path.hasPrefix("http") {
            success?(self)
            return
        }
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = Environment.currentEnvironment.s3Bucket
        uploadRequest.key = path.lastPathComponent
        uploadRequest.metadata = metadata
        if mediaType == .Video {
            uploadRequest.contentType = "video/mp4"
        } else {
            uploadRequest.contentType = "image/jpeg"
        }
        uploadRequest.body = path.fileURL
        AWSS3TransferManager.defaultS3TransferManager().upload(uploadRequest).continueWithBlock { [weak self] (task) -> AnyObject! in
            Dispatch.mainQueue.async { () -> Void in
                if let wrap = self?.wrap where wrap.valid && task.completed && (task.result != nil) {
                    success?(self)
                } else {
                    failure?(task.error)
                }
            }
            return task
        }
    }
    
    override func delete(success: ObjectBlock?, failure: FailureBlock?) {
        switch status {
        case .Ready:
            remove()
            success?(nil)
            break
        case .InProgress:
            failure?(NSError(message: (isVideo ? "video_is_uploading" : "photo_is_uploading").ls))
          break
        case .Finished:
            if uid == locuid {
                failure?(NSError(message: "publishing_in_progress".ls))
            } else {
                if let request = APIRequest.deleteCandy(self) {
                    request.send(success, failure: failure)
                } else {
                    failure?(nil)
                }
            }
         break
        }
    }
    
    override func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        if uploaded {
            APIRequest.candy(self).send(success, failure: failure)
        } else {
            failure?(NSError(message:(isVideo ? "video_is_uploading" : "photo_is_uploading").ls))
        }
    }
}

extension Message {
    override func add(success: ObjectBlock?, failure: FailureBlock?) {
        if let request = APIRequest.uploadMessage(self) {
            request.send(success, failure: failure)
        } else {
            failure?(nil)
        }
    }
}

extension Comment {
    
    override func add(success: ObjectBlock?, failure: FailureBlock?) {
        if candy?.uploaded ?? false {
            if let request = APIRequest.postComment(self) {
                request.send(success, failure: failure)
            } else {
                failure?(nil)
            }
        } else {
            failure?(nil)
        }
    }
    
    override func delete(success: ObjectBlock?, failure: FailureBlock?) {
        switch status {
        case .Ready:
            remove()
            success?(nil)
            break
        case .InProgress:
            failure?(NSError(message: "comment_is_uploading".ls))
            break
        case .Finished:
            if let candy = candy {
                switch candy.status {
                case .Ready:
                    remove()
                    success?(nil)
                    break
                case .InProgress:
                    failure?(NSError(message: (candy.isVideo ? "video_is_uploading" : "photo_is_uploading").ls))
                    break
                case .Finished:
                    if let request = APIRequest.deleteComment(self) {
                        request.send(success, failure: failure)
                    } else {
                        failure?(nil)
                    }
                    break;
                }
            } else {
                remove()
                success?(nil)
            }
            break
        }
    }
}
