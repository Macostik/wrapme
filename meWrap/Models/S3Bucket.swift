//
//  S3Bucket.swift
//  meWrap
//
//  Created by Sergey Maximenko on 5/12/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import AWSS3

class S3Bucket {
    
    struct Upload {
        
        let type: UploadType
        let url: String
        let contentType: String
        let metadata: [String:String]
    }
    
    enum UploadType: Int {
        case Candy = 10
        case Comment = 20
        case EditedCandy = 30
    }
    
    static let bucket: S3Bucket = {
        let bucket = S3Bucket()
        let accessKey = "AKIAIPEMEBV7F4GN2FVA"
        let secretKey = "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"
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey:accessKey, secretKey:secretKey)
        let configuration = AWSServiceConfiguration(region:.USWest2, credentialsProvider:credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        return bucket
    }()
    
    func upload(upload: Upload, progress: ((Int64, Int64, Int64) -> Void)? = nil, success: Block?, failure: FailureBlock?) {
        
        if upload.url.hasPrefix("http") {
            success?()
            return
        }
        
        var metadata = upload.metadata
        metadata["upload_type"] = "\(upload.type.rawValue)"
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = Environment.current.s3Bucket
        uploadRequest.metadata = metadata
        uploadRequest.key = (upload.url as NSString).lastPathComponent
        uploadRequest.contentType = upload.contentType
        uploadRequest.body = upload.url.fileURL
        AWSS3TransferManager.defaultS3TransferManager().upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            Dispatch.mainQueue.async { () -> Void in
                if task.completed && (task.result != nil) {
                    success?()
                } else {
                    failure?(task.error)
                }
            }
            return task
        }
        uploadRequest.uploadProgress = { sent, current, total in
            Dispatch.mainQueue.async({ () in
                progress?(sent, current, total)
            })
        }
    }
}