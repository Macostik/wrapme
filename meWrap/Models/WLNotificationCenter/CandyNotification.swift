//
//  CandyNotification.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/6/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class CandyNotification: Notification {
    
    var candy: Candy?
    
    internal override func setup(body: [String:AnyObject]) {
        super.setup(body)
        createDescriptor(Candy.self, body: body, key: "candy")
        descriptor?.container = Wrap.uid(body)
    }
    
    internal override func createEntry(descriptor: EntryDescriptor) {
        candy = getEntry(Candy.self, descriptor: descriptor, mapper: { (candy, data) in
            let oldPicture = candy.asset?.copy() as? Asset
            candy.map(data)
            if let newAsset = candy.asset {
                oldPicture?.cacheForAsset(newAsset)
            }
            if candy.sortedComments().contains({ $0.uploading != nil }) {
                Uploader.wrapUploader.start()
            }
        })
    }
}

class CandyAddNotification: CandyNotification {
    
    override func fetch(success: Block, failure: FailureBlock) {
        if let candy = candy {
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
        guard let candy = candy else { return }
        if inserted && candy.contributor != User.currentUser {
            candy.markAsUnread(true)
        }
        candy.notifyOnAddition()
    }
}

class CandyUpdateNotification: CandyNotification {
    
    override func fetch(success: Block, failure: FailureBlock) {
        if let candy = candy {
            if descriptor?.data == nil {
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
        guard let candy = candy else { return }
        if candy.editor != User.currentUser {
            candy.markAsUnread(true)
        }
        candy.notifyOnUpdate(.Default)
    }
}

class CandyDeleteNotification: CandyNotification {
    
    internal override func createEntry(descriptor: EntryDescriptor) {
        candy = getEntry(Candy.self, descriptor: descriptor, mapper: { _ in })
    }
    
    internal override func shouldCreateEntry(descriptor: EntryDescriptor) -> Bool {
        return descriptor.entryExists()
    }
    
    override func submit() {
        candy?.remove()
        if let wrap = candy?.wrap where wrap.valid && wrap.candies?.count < Constants.recentCandiesLimit {
            wrap.fetch(Wrap.ContentTypeRecent, success: nil, failure: nil)
        }
    }
}