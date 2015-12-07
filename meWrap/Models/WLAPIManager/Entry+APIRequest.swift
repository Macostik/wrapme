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

extension Entry {
    
    func add(success: WLObjectBlock?, failure: WLFailureBlock?) {
        success?(self)
    }
    
    func update(success: WLObjectBlock?, failure: WLFailureBlock?) {
        success?(self)
    }
    
    func delete(success: WLObjectBlock?, failure: WLFailureBlock?) {
        success?(self)
    }
}

extension User {
    override func fetch(success: ObjectBlock?, failure: FailureBlock?) {
        WLAPIRequest.user(self).send(success, failure: failure)
    }
}

extension Device {
    
}

extension Contribution {
    
}

extension Wrap {
    
    func uploadMessage(text: String) {
        if let message = Message.contribution(), let uploading = Uploading.uploading(message) {
            message.wrap = self
            message.text = text
            message.notifyOnAddition()
            WLUploadingQueue.upload(uploading, success: nil, failure: nil)
        }
    }
    
    func uploadAsset(asset: MutableAsset) {
        if let candy = Candy.candy(asset.type), let uploading = Uploading.uploading(candy) {
            candy.wrap = self
            candy.picture = asset.uploadablePicture(true)
            if let comment = asset.comment where !comment.isEmpty {
                Comment.comment(comment)?.candy = candy
            }
            candy.notifyOnAddition()
            WLUploadingQueue.upload(uploading, success: nil, failure: nil)
        }
    }
    
    func uploadAssets(assets: [MutableAsset]) {
        for asset in assets {
            runUnaryQueuedOperation("wl_upload_candies_queue", { [weak self] (operation) -> Void in
                self?.uploadAsset(asset)
                run_after(0.6, { () -> Void in
                    operation.finish()
                })
            })
        }
    }
    
    override func add(success: WLObjectBlock?, failure: WLFailureBlock?) {
        WLAPIRequest.uploadWrap(self).send(success, failure: failure)
    }
    
    override func update(success: WLObjectBlock?, failure: WLFailureBlock?) {
        WLAPIRequest.updateWrap(self).send(success, failure: failure)
    }
    
    override func delete(success: WLObjectBlock?, failure: WLFailureBlock?) {
        if deletable {
            
        } else {
            WLAPIRequest.leaveWrap(self).send(success, failure: failure)
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
            WLAPIRequest.deleteWrap(self).send(success, failure: failure)
            break
        }
    }
}

extension Uploading {
    
    class func uploading(contribution: Contribution) -> Self? {
        return uploading(contribution, event: .Add)
    }
    
    class func uploading(contribution: Contribution, event: Event) -> Self? {
        return uploading(self, contribution: contribution, event: event)
    }
    
    class func uploading<T>(type: T.Type, contribution: Contribution, event: Event) -> T? {
        if let uploading = EntryContext.sharedContext.insertEntry(entityName()) as? Uploading {
            uploading.type = event.rawValue
            uploading.contribution = contribution
            return uploading as? T
        } else {
            return nil
        }
    }
    
    func upload(success: WLObjectBlock?, failure: WLFailureBlock?) {
        if WLNetwork.sharedNetwork().reachable {
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

    func sendTypedRequest(success: WLObjectBlock?, failure: WLFailureBlock?) {
        if let type = Event(rawValue: self.type) {
            switch type {
            case .Add:
                add(success, failure: failure)
                break
            case .Update:
                update(success, failure: failure)
                break
            case .Delete:
                delete(success, failure: failure)
                break
            }
        }
    }
    
    override func add(success: WLObjectBlock?, failure: WLFailureBlock?) {
        if let contribution = contribution {
            if contribution.canBeUploaded || contribution.status == .Ready {
                contribution.add(success, failure: failure)
            } else {
                failure?(nil)
            }
        }
    }
    
    override func update(success: WLObjectBlock?, failure: WLFailureBlock?) {
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
        super.remove()
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
                notifyOnUpdate(.Default)
                if let uploading = Uploading.uploading(self, event: .Update) {
                    WLUploadingQueue.upload(uploading, success: nil, failure: nil)
                }
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
            if identifier == uploadIdentifier {
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
            setEditedPicture(asset.uploadablePicture(false))
            enqueueUpdate()?.show()
        }
    }
    
    func uploadComment(text: String) {
        if let comment = Comment.comment(text), let uploading = Uploading.uploading(comment) {
            commentCount++
            comment.candy = self
            comment.notifyOnAddition()
            run_after(0.3, { () -> Void in
                WLUploadingQueue.upload(uploading, success: nil, failure: nil)
            })
        }
    }

    override func add(success: WLObjectBlock?, failure: WLFailureBlock?) {

        var metadata = [
            "Accept" : "application/vnd.ravenpod+json;version=\(Environment.currentEnvironment.version)",
            Keys.UID.Device : Authorization.currentAuthorization.deviceUID ?? "",
            Keys.UID.User : contributor?.identifier ?? "",
            Keys.UID.Wrap : wrap?.identifier ?? "",
            Keys.UID.Upload : uploadIdentifier ?? "",
            Keys.ContributedAt : "\(createdAt.timestamp)"
        ]
        
        if let comment = (comments as? Set<Comment>)?.filter({ $0.uploading == nil }).first  {
            if let text = comment.text, let locuid = comment.uploadIdentifier {
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
    
    override func update(success: WLObjectBlock?, failure: WLFailureBlock?) {
        
        let metadata = [
            "Accept" : "application/vnd.ravenpod+json;version=\(Environment.currentEnvironment.version)",
            Keys.UID.Device : Authorization.currentAuthorization.deviceUID ?? "",
            Keys.UID.User : User.currentUser?.identifier ?? "",
            Keys.UID.Wrap : wrap?.identifier ?? "",
            Keys.UID.Candy : identifier ?? "",
            Keys.EditedAt : "\(updatedAt.timestamp)"
        ]
        
        uploadToS3Bucket(metadata, success: success, failure: failure)
    }
    
    func uploadToS3Bucket(metadata: [String:String], success: WLObjectBlock?, failure: WLFailureBlock?) {
        guard let original = picture?.original else {
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
            run_in_main_queue({ () -> Void in
                if let wrap = self?.wrap where wrap.valid && task.completed && (task.result != nil) {
                    success?(self)
                } else {
                    failure?(task.error)
                }
            })
            return task
        }
    }
    
    override func delete(success: WLObjectBlock?, failure: WLFailureBlock?) {
        switch status {
        case .Ready:
            remove()
            success?(nil)
            break
        case .InProgress:
            failure?(NSError(message: (isVideo ? "video_is_uploading" : "photo_is_uploading").ls))
          break
        case .Finished:
            if identifier == uploadIdentifier {
                failure?(NSError(message: "publishing_in_progress".ls))
            } else {
                WLAPIRequest.deleteCandy(self).send(success, failure: failure)
            }
         break
        }
    }
}

extension Message {
    override func add(success: WLObjectBlock?, failure: WLFailureBlock?) {
        WLAPIRequest.uploadMessage(self).send(success, failure: failure)
    }
}

extension Comment {
    
    override func add(success: WLObjectBlock?, failure: WLFailureBlock?) {
        if candy?.uploaded ?? false {
            WLAPIRequest.postComment(self).send(success, failure: failure)
        } else {
            failure?(nil)
        }
    }
    
    override func delete(success: WLObjectBlock?, failure: WLFailureBlock?) {
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
                    WLAPIRequest.deleteComment(self).send(success, failure: failure)
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
