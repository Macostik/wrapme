//
//  Contribution.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(Uploading)
final class Uploading: Entry {
    
    override class func entityName() -> String { return "Uploading" }
    
    var inProgress = false
}

@objc(Contribution)
class Contribution: Entry {
    
    override class func entityName() -> String { return "Contribution" }
    
    class func recentContributions() -> [Contribution] {
        var contributions = [Contribution]()
        let date = NSDate.now().startOfDay()
        let comments: [Contribution] = FetchRequest<Comment>().query("createdAt > %@ AND contributor != nil", date).execute()
        contributions.appendContentsOf(comments)
        let candies: [Contribution] = FetchRequest<Candy>().query("createdAt > %@ AND contributor != nil", date).execute()
        contributions.appendContentsOf(candies)
        return contributions.sort({ $0.createdAt > $1.createdAt })
    }
    
    class func recentContributions(limit: Int) -> [Contribution] {
        let contributions = recentContributions()
        if contributions.count > limit {
            return Array(contributions[0..<limit])
        } else {
            return contributions
        }
    }
    
    func statusOfAnyUploadingType() -> ContributionStatus {
        if let uploading = uploading {
            if uploading.inProgress {
                return .InProgress
            } else {
                return .Ready
            }
        } else {
            return .Finished
        }
    }
    
    func statusOfUploadingEvent(event: Event) -> ContributionStatus {
        if let uploading = uploading where uploading.type == event.rawValue {
            if uploading.inProgress {
                return .InProgress
            } else {
                return .Ready
            }
        } else {
            return .Finished
        }
    }
    
    var status: ContributionStatus { return statusOfUploadingEvent(.Add) }
    
    var uploaded: Bool { return status == .Finished }
    
    var deletable: Bool { return contributor?.current ?? false }
    
    var canBeUploaded: Bool { return true }
    
    override class func prefetchDescriptors(inout descriptors: Set<EntryDescriptor>, inDictionary dictionary: [String : AnyObject]?) {
        super.prefetchDescriptors(&descriptors, inDictionary: dictionary)
        User.prefetchDescriptors(&descriptors, inDictionary: dictionary?["contributor"] as? [String:AnyObject])
    }
    
    private var _uploadingView: UploadingView?
    var uploadingView: UploadingView? {
        get {
            if _uploadingView == nil && uploading != nil {
                _uploadingView = UploadingView(contribution: self)
            }
            return _uploadingView
        }
        set {
            _uploadingView = newValue
        }
    }
    
    func updateProgress(progress: CGFloat) {
        _uploadingView?.updateProgress(progress)
    }
    
    func uploadToS3Bucket(metadata: [String:String], success: ObjectBlock?, failure: FailureBlock?) {
        
        guard let asset = asset, let original = asset.original where original.isExistingFilePath else {
            Logger.log("Failed S3 uploading, no file: \(metadata)")
            remove()
            failure?(NSError(code: ResponseCode.UploadFileNotFound.rawValue))
            return
        }
        
        let contentType = asset.contentType()
        Logger.log("Uploading \(contentType) to S3 bucket: \(metadata)")
        
        S3Bucket.bucket.upload(original, contentType: contentType, metadata: metadata, progress: { [weak self] _, current, total in
            let progress = smoothstep(0, 1, CGFloat(current) / CGFloat(total))
            self?.updateProgress(progress)
            }, success: { [weak self] () in
                if self?.valid == true {
                    Logger.log("Uploading \(contentType) to S3 bucket success: \(metadata)")
                    success?(self)
                } else {
                    Logger.log("Uploading \(contentType) to S3 bucket error due to invalid entry: \(metadata)")
                    failure?(nil)
                }
            }, failure: { error in
                Logger.log("Uploading \(contentType) to S3 bucket error: \(metadata)\n \(error ?? "")")
                failure?(error)
        })
    }
}
