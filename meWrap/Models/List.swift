//
//  List.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc protocol ListEntry: NSObjectProtocol {
    func listSort(entry: ListEntry) -> Bool
    func listSortDate() -> NSDate
    func listEntryEqual(entry: ListEntry) -> Bool
}

@objc protocol ListNotifying {
    optional func listChanged(list: List)
}

class List: Notifier {
    
    var entries = [ListEntry]() {
        didSet {
            didChange()
        }
    }
    
    internal func _add(entry: ListEntry) -> Bool {
        if !entries.contains({ $0.listEntryEqual(entry) }) {
            entries.append(entry)
            return true
        } else {
            return false
        }
    }
    
    func add(entry: ListEntry) {
        if _add(entry) {
            sort()
        }
    }
    
    func addEntries(entries: [ListEntry]) {
        let count = self.entries.count
        for entry in entries {
            _add(entry)
        }
        if count != self.entries.count {
            sort()
        }
    }
    
    func sort() {
        entries = entries.sort({ $0.listSort($1) })
    }
    
    func sort(entry: ListEntry) {
        _add(entry)
        sort()
    }
    
    func remove(entry: ListEntry) {
        if let index = entries.indexOf({ $0.listEntryEqual(entry) }) {
            entries.removeAtIndex(index)
        }
    }
    
    internal func didChange() {
        notify { (receiver) -> Void in
            receiver.listChanged?(self)
        }
    }
    
    subscript(index: Int) -> ListEntry? {
        return (index >= 0 && index < count) ? entries[index] : nil
    }
}

@objc protocol BaseOrderedContainer {
    var count: Int { get }
    func objectAtIndex(index: Int) -> AnyObject
    func tryAt(index: Int) -> AnyObject?
}

extension NSArray: BaseOrderedContainer {
    func tryAt(index: Int) -> AnyObject? {
        return (index >= 0 && index < count) ? self[index] : nil
    }
}

extension List: BaseOrderedContainer {
    var count: Int {
        return entries.count
    }
    func tryAt(index: Int) -> AnyObject? {
        return (index >= 0 && index < count) ? entries[index] : nil
    }
    func objectAtIndex(index: Int) -> AnyObject {
        return entries[index]
    }
}

@objc protocol PaginatedListNotifying: ListNotifying {
    optional func paginatedListDidStartLoading(list: PaginatedList)
    optional func paginatedListDidFinishLoading(list: PaginatedList)
}

class PaginatedList: List {
    
    convenience init(request: PaginatedRequest) {
        self.init()
        self.request = request
    }
    
    convenience init(entries: [ListEntry], request: PaginatedRequest) {
        self.init(request: request)
        self.addEntries(entries)
    }
    
    var completed: Bool = false {
        didSet {
            if completed != oldValue {
                didChange()
            }
        }
    }
    
    var request: PaginatedRequest?
    
    private var loadingTypes = Set<PaginatedRequestType>()
    
    private func addLoadingType(type: PaginatedRequestType) {
        loadingTypes.insert(type)
        if loadingTypes.count == 1 {
            notify({ (receiver) -> Void in
                receiver.paginatedListDidStartLoading?(self)
            })
        }
    }
    
    private func removeLoadingType(type: PaginatedRequestType) {
        loadingTypes.remove(type)
        if loadingTypes.count == 0 {
            notify({ (receiver) -> Void in
                receiver.paginatedListDidFinishLoading?(self)
            })
        }
    }
    
    func fresh(success: ObjectBlock?, failure: FailureBlock?) {
        send(.Fresh, success: success, failure: failure)
    }
    
    func newer(success: ObjectBlock?, failure: FailureBlock?) {
        send(.Newer, success: success, failure: failure)
    }
    
    func older(success: ObjectBlock?, failure: FailureBlock?) {
        send(.Older, success: success, failure: failure)
    }
    
    func send(type: PaginatedRequestType, success: ObjectBlock?, failure: FailureBlock?) {
        if let request = request where !loadingTypes.contains(type) {
            addLoadingType(type)
            RunQueue.fetchQueue.run { [weak self] (finish) -> Void in
                if let list = self {
                    request.type = type
                    list.configureRequest(request)
                    request.send({ (object) -> Void in
                        list.handleResponse(object, type: type)
                        list.removeLoadingType(type)
                        finish()
                        success?(object)
                        }, failure: { (error) -> Void in
                            list.removeLoadingType(type)
                            finish()
                            failure?(error)
                    })
                } else {
                    finish()
                    success?(nil)
                }
            }
        } else {
            failure?(nil)
        }
    }
    
    internal func handleResponse(entries: AnyObject?, type: PaginatedRequestType) {
        if let entries = entries as? [ListEntry] {
            addEntries(entries)
            if entries.isEmpty && type == .Older {
                completed = true
            }
        }
    }
    
    internal func newerPaginationDate() -> NSDate? {
        let dates = entries.map({ (entry) -> NSDate in return entry.listSortDate() })
        return dates.maxElement({ $0 < $1 })
    }
    
    internal func olderPaginationDate() -> NSDate? {
        let dates = entries.map({ (entry) -> NSDate in return entry.listSortDate() })
        return dates.maxElement({ $0 > $1 })
    }
    
    internal func configureRequest(request: PaginatedRequest) {
        if entries.count == 0 {
            request.type = .Fresh
        } else {
            request.newer = newerPaginationDate()
            request.older = olderPaginationDate()
        }
    }
}

extension Entry: ListEntry {
    func listSort(entry: ListEntry) -> Bool {
        return listSortDate() > entry.listSortDate()
    }
    func listSortDate() -> NSDate {
        return createdAt
    }
    func listEntryEqual(entry: ListEntry) -> Bool {
        return self == (entry as? Entry)
    }
}

extension Wrap {
    
    override func listSort(entry: ListEntry) -> Bool {
        if let wrap = entry as? Wrap {
            if wrap.liveBroadcasts.count > 0 {
                if liveBroadcasts.count > 0 {
                    return name < wrap.name
                } else {
                    return false
                }
            } else {
                if liveBroadcasts.count > 0 {
                    return true
                } else {
                    return updatedAt > wrap.updatedAt
                }
            }
        } else {
            return super.listSort(entry)
        }
    }
    
    override func listSortDate() -> NSDate {
        return updatedAt
    }
}

