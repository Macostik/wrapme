//
//  Entry+Base.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/11/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CoreData
import Photos

extension Entry {
    
    class func entry() -> Self? {
        return entry(self)
    }
    
    class func entry<T>(type: T.Type) -> T? {
        if let entry = NSEntityDescription.insertNewObjectForEntityForName(entityName(), inManagedObjectContext: EntryContext.sharedContext) as? Entry {
            entry.uid = NSString.GUID()
            entry.createdAt = NSDate.now()
            entry.updatedAt = entry.createdAt
            return entry as? T
        } else {
            return nil
        }
    }
    
    func markAsRead() {
        if valid && unread {
            unread = false
        }
    }
    
    func markAsUnread() {
        if valid && !unread {
            unread = true
        }
    }
    
    func remove() {
        let context = EntryContext.sharedContext
        context.assureSave {[weak self] () -> Void in
            if let entry = self {
                let container = entry.container
                entry.notifyOnDeleting()
                context.deleteEntry(entry)
                container?.notifyOnUpdate(.ContentDeleted)
            }
        }
    }
    
    func touch() {
        touch(NSDate.now())
    }
    
    func touch(date: NSDate) {
        if let container = container {
            container.touch(date)
        }
        updatedAt = date
    }
    
    func fetched() -> Bool {
        return true
    }
    
    func recursivelyFetched() -> Bool {
        var entry: Entry? = self
        while let _entry = entry {
            if !_entry.fetched() {
                return false
            }
            entry = _entry.container
        }
        return true
    }
}

extension User {
    
    class func channelName() -> String {
        return "\(User.currentUser?.uid ?? "")-\(Authorization.currentAuthorization.deviceUID ?? "")"
    }
    
    override func fetched() -> Bool {
        return !(avatar?.small?.isEmpty ?? true) && !(name?.isEmpty ?? true)
    }
}

extension Device {
    
}

extension Contribution {
    
    class func contribution() -> Self? {
        return contribution(self)
    }
    
    class func contribution<T>(type: T.Type) -> T? {
        if let contributrion = entry() {
            contributrion.locuid = contributrion.uid
            contributrion.contributor = User.currentUser
            return contributrion as? T
        } else {
            return nil
        }
    }
}

extension Wrap {
    
    class func wrap() -> Wrap? {
        if let wrap = contribution() {
            if let contributor = wrap.contributor {
                contributor.mutableWraps.addObject(wrap)
                wrap.contributors = NSSet(object: contributor)
            }
            return wrap
        } else {
            return nil
        }
    }
    
    override func fetched() -> Bool {
        return !(name?.isEmpty ?? true) && contributor != nil
    }
}

extension Candy {
    
    class func candy(mediaType: MediaType) -> Candy? {
        if let candy = contribution() {
            candy.mediaType = mediaType
            return candy
        } else {
            return nil
        }
    }
    
    override func fetched() -> Bool {
        return wrap != nil && !(asset?.original?.isEmpty ?? true)
    }
    
    func editAsset(newAsset: Asset) {
        switch status {
        case .Ready:
            asset = newAsset
            break
        case .InProgress:
            break
        case .Finished:
            touch()
            editedAt = NSDate.now()
            editor = User.currentUser
            asset = newAsset
            break
        }
    }
    
    func download(success: Block?, failure: FailureBlock?) {
        if (PHPhotoLibrary.authorizationStatus() == .Denied) {
            failure?(NSError(message:"downloading_privacy_settings".ls))
        } else {
            guard let url = asset?.original else {
                failure?(nil)
                return
            }
            if mediaType == .Video {
                
                if url.isExistingFilePath {
                    PHPhotoLibrary.addAsset({ () -> PHAssetChangeRequest? in
                        return PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url.fileURL!)
                        }, collectionTitle: Constants.albumName, success: success, failure: failure)
                } else {
                    
                    let task = NSURLSession.sharedSession().downloadTaskWithURL(url.URL!, completionHandler: { (location, response, error) -> Void in
                        if let error = error {
                            run_in_main_queue({ () -> Void in
                                failure?(error)
                            })
                        } else {
                            if let location = location {
                                do {
                                    let url = NSURL(fileURLWithPath: "Documents/\(NSString.GUID()).mp4")
                                    let manager = NSFileManager.defaultManager()
                                    try manager.moveItemAtURL(location, toURL: url)
                                    if url.checkResourceIsReachableAndReturnError(nil) {
                                        PHPhotoLibrary.addAsset({ () -> PHAssetChangeRequest? in
                                            return PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)
                                            }, collectionTitle: Constants.albumName, success: { () -> Void in
                                                try! manager.removeItemAtURL(url)
                                            }, failure: { (error) -> Void in
                                                try! manager.removeItemAtURL(url)
                                        })
                                    } else {
                                        failure?(NSError(message: "Local video file is not reachable"))
                                    }
                                } catch {
                                    
                                }
                            } else {
                                run_in_main_queue({ () -> Void in
                                    failure?(nil)
                                })
                            }
                        }
                    })
                    
                    task.resume()
                }
            } else {
                BlockImageFetching.enqueue(url, success: { (image) -> Void in
                    if let image = image {
                        PHPhotoLibrary.addAsset({ () -> PHAssetChangeRequest? in
                            return PHAssetChangeRequest.creationRequestForAssetFromImage(image)
                            }, collectionTitle: Constants.albumName, success: success, failure: failure)
                    } else {
                        failure?(nil)
                    }
                    }, failure: failure)
            }
        }
    }
}

extension Message {
    
    override func fetched() -> Bool {
        return !(text?.isEmpty ?? true) && wrap != nil
    }
}

extension Comment {
    
    class func comment(text: String) -> Comment? {
        if let comment = contribution() {
            comment.text = text
            return comment
        } else {
            return nil
        }
    }
    
    override func fetched() -> Bool {
        return !(text?.isEmpty ?? true) && candy != nil
    }
}