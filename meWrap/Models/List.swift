//
//  List.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class List<T: Equatable> {
    
    var sorter: (lhs: T, rhs: T) -> Bool = { _ in return true }
    
    convenience init(sorter: (lhs: T, rhs: T) -> Bool) {
        self.init()
        self.sorter = sorter
    }
    
    var entries = [T]()
    
    let didChangeNotifier = Notifier<List<T>>()
    
    internal func _add(entry: T) -> Bool {
        if !entries.contains(entry) {
            entries.append(entry)
            return true
        } else {
            return false
        }
    }
    
    func add(entry: T) {
        if _add(entry) {
            sort()
        }
    }
    
    func addEntries<S: SequenceType where S.Generator.Element == T>(entries: S) {
        let count = self.entries.count
        for entry in entries {
            _add(entry)
        }
        if count != self.entries.count {
            sort()
        }
    }
    
    func sort(entry: T) {
        _add(entry)
        sort()
    }
    
    func sort() {
        entries = entries.sort(sorter)
        didChange()
    }
    
    func remove(entry: T) {
        if let index = entries.indexOf(entry) {
            entries.removeAtIndex(index)
            didChange()
        }
    }
    
    internal func didChange() {
        didChangeNotifier.notify(self)
    }
    
    subscript(index: Int) -> T? {
        return (index >= 0 && index < count) ? entries[index] : nil
    }
}

protocol BaseOrderedContainer {
    associatedtype ElementType
    var count: Int { get }
    subscript (safe index: Int) -> ElementType? { get }
}

extension Array: BaseOrderedContainer {}

extension List: BaseOrderedContainer {
    var count: Int { return entries.count }
    subscript (safe index: Int) -> T? {
        return entries[safe: index]
    }
}

protocol PaginatedListProtocol: BaseOrderedContainer {
    associatedtype PaginatedEntryType: Equatable
    func fresh(success: ([PaginatedEntryType] -> ())?, failure: FailureBlock?)
    func newer(success: ([PaginatedEntryType] -> ())?, failure: FailureBlock?)
    func older(success: ([PaginatedEntryType] -> ())?, failure: FailureBlock?)
    var completed: Bool { get set }
    var didChangeNotifier: Notifier<List<PaginatedEntryType>> { get }
    var didStartLoading: Notifier<PaginatedList<PaginatedEntryType>> { get }
    var didFinishLoading: Notifier<PaginatedList<PaginatedEntryType>> { get }
}

class PaginatedList<T: Equatable>: List<T>, PaginatedListProtocol {
    
    convenience init<S: SequenceType where S.Generator.Element == T>(entries: S, request: PaginatedRequest<[T]>, sorter: (lhs: T, rhs: T) -> Bool) {
        self.init(sorter: sorter)
        self.request = request
        self.entries = entries.sort(sorter)
    }
    
    let didStartLoading = Notifier<PaginatedList<T>>()
    let didLoadEntries = Notifier<[T]>()
    let didFinishLoading = Notifier<PaginatedList<T>>()
    
    var completed: Bool = false {
        didSet {
            if completed != oldValue {
                didChange()
            }
        }
    }
    
    var request: PaginatedRequest<[T]>?
    
    private var loadingTypes = Set<PaginatedRequestType>()
    
    private func addLoadingType(type: PaginatedRequestType) {
        loadingTypes.insert(type)
        if loadingTypes.count == 1 {
            didStartLoading.notify(self)
        }
    }
    
    private func removeLoadingType(type: PaginatedRequestType) {
        loadingTypes.remove(type)
        if loadingTypes.count == 0 {
            didFinishLoading.notify(self)
        }
    }
    
    func fresh(success: ([T] -> ())?, failure: FailureBlock?) {
        send(.Fresh, success: success, failure: failure)
    }
    
    func newer(success: ([T] -> ())?, failure: FailureBlock?) {
        send(.Newer, success: success, failure: failure)
    }
    
    func older(success: ([T] -> ())?, failure: FailureBlock?) {
        send(.Older, success: success, failure: failure)
    }
    
    func send(type: PaginatedRequestType, success: ([T] -> ())?, failure: FailureBlock?) {
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
                    failure?(nil)
                }
            }
        } else {
            failure?(nil)
        }
    }
    
    internal func handleResponse(entries: [T], type: PaginatedRequestType) {
        didLoadEntries.notify(entries)
        if entries.isEmpty {
            if type == .Older {
                completed = true
            } else {
                didChange()
            }
        } else {
            addEntries(entries)
        }
    }
    
    var newerThen: ([T] -> NSDate?)?
    
    var olderThen: ([T] -> NSDate?)?
    
    internal func configureRequest(request: PaginatedRequest<[T]>) {
        if entries.count == 0 {
            request.type = .Fresh
        } else {
            request.newer = newerThen?(entries)
            request.older = olderThen?(entries)
        }
    }
}

