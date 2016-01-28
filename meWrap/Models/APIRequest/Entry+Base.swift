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
    
    class func entry() -> Self {
        return entry(self)
    }
    
    class func entry<T: Entry>(type: T.Type) -> T {
        let entry = NSEntityDescription.insertNewObjectForEntityForName(entityName(), inManagedObjectContext: EntryContext.sharedContext) as! T
        entry.uid = NSString.GUID()
        entry.createdAt = NSDate.now()
        entry.updatedAt = entry.createdAt
        return entry
    }
    
    func markAsUnread(unread: Bool) {
        if valid && self.unread != unread {
            willBecomeUnread(unread)
            self.unread = unread
        }
    }
    
    func willBecomeUnread(unread: Bool) {
        
    }
    
    func remove() {
        let context = EntryContext.sharedContext
        _ = try? context.save()
        let container = self.container
        notifyOnDeleting()
        context.deleteEntry(self)
        container?.notifyOnUpdate(.ContentDeleted)
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
    
    class func contribution() -> Self {
        let contributrion = entry()
        contributrion.locuid = contributrion.uid
        contributrion.contributor = User.currentUser
        return contributrion
    }
}

extension Wrap {
    
    class func wrap() -> Wrap {
        let wrap = contribution()
        if let contributor = wrap.contributor {
            wrap.contributors = [contributor]
        }
        return wrap
    }
    
    override func fetched() -> Bool {
        return !(name?.isEmpty ?? true) && contributor != nil
    }
}

extension Candy {
    
    class func candy(mediaType: MediaType) -> Candy {
        let candy = contribution()
        candy.mediaType = mediaType
        return candy
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
            updatedAt = NSDate.now()
            editedAt = updatedAt
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
                    PHPhotoLibrary.addVideoAtFileUrl(url.fileURL!, success: success, failure: failure)
                } else {
                    
                    let task = NSURLSession.sharedSession().downloadTaskWithURL(url.URL!, completionHandler: { (location, response, error) -> Void in
                        if let error = error {
                            Dispatch.mainQueue.async({ failure?(error) })
                        } else {
                            if let location = location {
                                let url = NSURL(fileURLWithPath: "Documents/\(NSString.GUID()).mp4")
                                let manager = NSFileManager.defaultManager()
                                _ = try? manager.moveItemAtURL(location, toURL: url)
                                if url.checkResourceIsReachableAndReturnError(nil) {
                                    PHPhotoLibrary.addVideoAtFileUrl(url, success: { () -> Void in
                                        _ = try? manager.removeItemAtURL(url)
                                        success?()
                                        }, failure: { (error) -> Void in
                                            _ = try? manager.removeItemAtURL(url)
                                            failure?(error)
                                    })
                                } else {
                                    Dispatch.mainQueue.async({ failure?(NSError(message: "Local video file is not reachable")) })
                                }
                            } else {
                                Dispatch.mainQueue.async({ failure?(error) })
                            }
                        }
                    })
                    
                    task.resume()
                }
            } else {
                BlockImageFetching.enqueue(url, success: { (image) -> Void in
                    PHPhotoLibrary.addImage(image, success: success, failure: failure)
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
    
    class func comment(text: String) -> Comment {
        let comment = contribution()
        comment.text = text
        return comment
    }
    
    override func fetched() -> Bool {
        return !(text?.isEmpty ?? true) && candy != nil
    }
}