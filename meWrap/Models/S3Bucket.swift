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
    
    static let bucket: S3Bucket = {
        let bucket = S3Bucket()
        let accessKey = "AKIAIPEMEBV7F4GN2FVA"
        let secretKey = "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"
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey:accessKey, secretKey:secretKey)
        let configuration = AWSServiceConfiguration(region:.USWest2, credentialsProvider:credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        return bucket
    }()
    
    func upload(url: String, contentType: String, metadata: [String:String], progress: ((Int64, Int64, Int64) -> Void)? = nil, success: Block?, failure: FailureBlock?) {
                
        if url.hasPrefix("http") {
            success?()
            return
        }
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = Environment.current.s3Bucket
        uploadRequest.metadata = metadata
        uploadRequest.key = (url as NSString).lastPathComponent
        uploadRequest.contentType = contentType
        uploadRequest.body = url.fileURL
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