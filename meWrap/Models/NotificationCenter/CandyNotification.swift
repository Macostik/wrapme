//
//  CandyNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class CandyNotification: EntryNotification<Candy> {
    
    override func dataKey() -> String { return "candy" }
    
    override func mapEntry(candy: Candy, data: [String : AnyObject]) {
        if type != .CandyDelete {
            
            if originatedByCurrentUser && candy.status == .Ready {
                candy.uploading = nil
            }
            
            let oldPicture = candy.asset?.copy() as? Asset
            candy.map(data)
            if let newAsset = candy.asset where originatedByCurrentUser {
                oldPicture?.cacheForAsset(newAsset)
            }
            if candy.sortedComments().contains({ $0.uploading != nil }) {
                Uploader.wrapUploader.start()
            }
        }
    }
}

class CandyAddNotification: CandyNotification {
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if let candy = _entry {
            candy.recursivelyFetchIfNeeded({ _ in
                if let asset = candy.asset {
                    asset.fetch(success)
                } else {
                    success()
                }
                }, failure: failure)
        } else {
            success()
        }
    }
    
    override func submit() {
        guard let candy = _entry else { return }
        if inserted && candy.contributor != User.currentUser {
            candy.markAsUnread(true)
            for comment in candy.comments {
                comment.markAsUnread(true)
            }
        }
        candy.notifyOnAddition()
        if candy.contributor?.current == false && !isHistorycal {
            EntryToast.showCandyAddition(candy)
        }
    }
    
    override func canBeHandled() -> Bool { return Authorization.active }
}

class CandyUpdateNotification: CandyNotification {
    
    override func fetch(success: Block, failure: FailureBlock) {
        createEntryIfNeeded()
        if let candy = _entry {
            if entryData == nil {
                candy.fetch({ (_) -> Void in
                    if let asset = candy.asset {
                        asset.fetch(success)
                    } else {
                        success()
                    }
                    }, failure: failure)
            } else {
                if let asset = candy.asset {
                    asset.fetch(success)
                } else {
                    success()
                }
            }
        } else {
            success()
        }
    }
    
    override func submit() {
        guard let candy = _entry else { return }
        if candy.editor != User.currentUser {
            candy.markAsUpdateUnread(true)
        }
        candy.notifyOnUpdate(.Default)
        if candy.editor?.current == false && !isHistorycal {
            EntryToast.showCandyUpdate(candy)
        }
    }
    
    override func canBeHandled() -> Bool { return Authorization.active }
}

class CandyDeleteNotification: CandyNotification {
    
    override func mapEntry(candy: Candy, data: [String : AnyObject]) { }
    
    override func submit() {
        _entry?.remove()
        if let wrap = _entry?.wrap where wrap.valid && wrap.candies.count < Constants.recentCandiesLimit {
            wrap.fetch(Wrap.ContentTypeRecent, success: nil, failure: nil)
        }
    }
}