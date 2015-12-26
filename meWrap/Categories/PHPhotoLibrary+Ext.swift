//
//  PHPhotoLibrary+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/13/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import Photos

extension PHPhotoLibrary {
    
    class func collectionWithTitle(title: String) -> PHAssetCollectionChangeRequest {
        let result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumRegular, options:nil)
        
        var request: PHAssetCollectionChangeRequest?
        result.enumerateObjectsUsingBlock { (object, index, stop) -> Void in
            if let collection = object as? PHAssetCollection where collection.localizedTitle == title {
                request = PHAssetCollectionChangeRequest(forAssetCollection: collection)
                stop.memory = true
            }
        }
        if let request = request {
            return request
        } else {
            return PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(title)
        }
    }
    
    class func addImage(image: UIImage, success: Block?, failure: FailureBlock?) {
        addAsset({ PHAssetChangeRequest.creationRequestForAssetFromImage(image) }, success: success, failure: failure)
    }
    
    class func addImageAtFileUrl(url: NSURL, success: Block?, failure: FailureBlock?) {
        addAsset({ PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(url) }, success: success, failure: failure)
    }
    
    class func addVideoAtFileUrl(url: NSURL, success: Block?, failure: FailureBlock?) {
        addAsset({ PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url) }, success: success, failure: failure)
    }
    
    class func addAsset(assetBlock: Void -> PHAssetChangeRequest?, success: Block?, failure: FailureBlock?) {
        sharedPhotoLibrary().performChanges({ () -> Void in
            if let changeRequest = assetBlock() {
                let collectonRequest = collectionWithTitle(Constants.albumName)
                if let asset = changeRequest.placeholderForCreatedAsset {
                    collectonRequest.addAssets([asset])
                }
            }
            }) { (status, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let error = error {
                        failure?(error)
                    } else {
                        success?()
                    }
                })
        }
    }
}
