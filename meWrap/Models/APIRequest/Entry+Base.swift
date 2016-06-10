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

func insertEntry<T: Entry>() -> T {
    let entry: T = EntryContext.sharedContext.insertEntry(T.entityName()) as! T
    entry.uid = GUID()
    entry.createdAt = NSDate.now()
    entry.updatedAt = entry.createdAt
    return entry
}

func insertContribution<T: Contribution>() -> T {
    return specify(insertEntry(), {
        $0.locuid = $0.uid
        $0.contributor = User.currentUser
    })
}

func insertWrap() -> Wrap {
    return specify(insertContribution(), {
        if let contributor = $0.contributor {
            $0.contributors = [contributor]
        }
    })
}

func insertCandy(mediaType: MediaType) -> Candy {
    return specify(insertContribution(), { $0.mediaType = mediaType })
}

func insertComment(text: String) -> Comment {
    return specify(insertContribution(), { $0.text = text })
}

extension Entry {
    
    func markAsUnread(unread: Bool) {
        if valid && self.unread != unread {
            willBecomeUnread(unread)
            self.unread = unread
        }
    }
    
    func willBecomeUnread(unread: Bool) { }
    
    func remove() {
        let context = EntryContext.sharedContext
        _ = try? context.save()
        let container = self.container
        notifyOnDeleting()
        context.deleteEntry(self)
        container?.notifyOnUpdate(.ContentDeleted)
    }
    
    func touch(date: NSDate = NSDate.now()) {
        container?.touch(date)
        updatedAt = date
    }
    
    func fetched() -> Bool {
        return true
    }
}

extension User {
    
    static func uuid() -> String {
        return "\(User.currentUser?.uid ?? "")-\(Authorization.current.deviceUID)"
    }
    
    override func fetched() -> Bool {
        return !(avatar?.small?.isEmpty ?? true) && !(name?.isEmpty ?? true)
    }
}

extension Wrap {
    
    override func fetched() -> Bool {
        return !(name?.isEmpty ?? true) && contributor != nil
    }
}

extension Candy {
    
    override func markAsUnread(unread: Bool) {
        if !unread {
            markAsUpdateUnread(false)
        }
        super.markAsUnread(unread)
    }
    
    override func willBecomeUnread(unread: Bool) {
        if let wrap = wrap {
            if unread {
                wrap.numberOfUnreadInboxItems += 1
            } else if wrap.numberOfUnreadInboxItems > 0 {
                wrap.numberOfUnreadInboxItems -= 1
            }
            wrap.notifyOnUpdate(.InboxChanged)
        }
    }
    
    func markAsUpdateUnread(unread: Bool) {
        if valid && self.updateUnread != unread {
            self.updateUnread = unread
            if let wrap = wrap {
                if unread {
                    wrap.numberOfUnreadInboxItems += 1
                } else if wrap.numberOfUnreadInboxItems > 0 {
                    wrap.numberOfUnreadInboxItems -= 1
                }
                wrap.notifyOnUpdate(.InboxChanged)
            }
        }
    }
    
    override func fetched() -> Bool {
        return wrap != nil && !(asset?.original?.isEmpty ?? true)
    }
    
    func editAsset(newAsset: Asset) {
        switch status {
        case .Ready:
            asset = newAsset
        case .InProgress: break
        case .Finished:
            updatedAt = NSDate.now()
            editedAt = updatedAt
            editor = User.currentUser
            asset = newAsset
        }
    }
    
    func download(success: Block?, failure: FailureBlock?) {
        if (PHPhotoLibrary.authorizationStatus() == .Denied) {
            failure?(NSError(message:"downloading_privacy_settings".ls))
        } else {
            DownloadingView.downloadCandy(self, message: Toast.downloadingMediaMessageForCandy(self), success: { (url) in
                if self.mediaType == .Video {
                    PHPhotoLibrary.addVideoAtFileUrl(url, success: success, failure: failure)
                } else {
                    PHPhotoLibrary.addImageAtFileUrl(url, success: success, failure: failure)
                }
                }, failure: failure)
        }
    }
}

extension Message {
    
    override func fetched() -> Bool {
        return !(text?.isEmpty ?? true) && wrap != nil
    }
    
    override func willBecomeUnread(unread: Bool) {
        if let wrap = wrap {
            if unread {
                wrap.numberOfUnreadMessages += 1
            } else if wrap.numberOfUnreadMessages > 0 {
                wrap.numberOfUnreadMessages -= 1
            }
            wrap.notifyOnUpdate(.NumberOfUnreadMessagesChanged)
        }
    }
}

extension Comment {
    
    override func fetched() -> Bool {
        return !(text?.isEmpty ?? true) && candy != nil
    }
    
    override func willBecomeUnread(unread: Bool) {
        if let wrap = candy?.wrap {
            if unread {
                wrap.numberOfUnreadInboxItems += 1
            } else if wrap.numberOfUnreadInboxItems > 0 {
                wrap.numberOfUnreadInboxItems -= 1
            }
            wrap.notifyOnUpdate(.InboxChanged)
        }
    }
}