//
//  ImageCache.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import CryptoSwift

class ImageCache: NSObject {
    
    private static var DefaultCacheSize = 524288000
    
    var compressionQuality: CGFloat = 1
    
    var permitted = false
    
    var path = ""
    
    var size: Int = 0 {
        didSet {
            if size > 0 {
                enqueueCheckSize()
            }
        }
    }
    
    var uids = Set<String>()
    
    static var defaultCache: ImageCache = {
        let cache = ImageCache(name: "wl_ImagesCache")
        cache.size = DefaultCacheSize
        return cache
    }()
    
    static var uploadingCache: ImageCache = {
        let cache = ImageCache(name: "wl_UploadingImagesCache")
        cache.compressionQuality = 0.75
        return cache
    }()
    
    private var token: dispatch_once_t = 0
    
    init(name: String) {
        super.init()
        let manager = NSFileManager.defaultManager()
        dispatch_once(&token) {
            if let path = manager.containerURLForSecurityApplicationGroupIdentifier(Constants.groupIdentifier)?.path {
                manager.changeCurrentDirectoryPath(path)
            }
        }
        path = "Documents/" + name
        do {
            try manager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            permitted = true
            uids = Set(try manager.contentsOfDirectoryAtPath(path))
        } catch {
        }
    }
    
    subscript(uid: String) -> UIImage? {
        get {
            return read(uid)
        }
        set(newValue) {
            if let image = newValue {
                write(image, uid: uid)
            }
        }
    }
    
    func getPath(uid: String) -> String {
        return "\(path)/\(uid)"
    }
    
    func read(uid: String) -> UIImage? {
        if permitted {
            let image = UIImage(contentsOfFile: getPath(uid))
            InMemoryImageCache.instance[uid] = image
            return image
        }
        return nil
    }
    
    func write(image: UIImage, uid: String) {
        if permitted, let data = UIImageJPEGRepresentation(image, compressionQuality) where data.length > 0 {
            data.writeToFile(getPath(uid), atomically: false)
        }
        InMemoryImageCache.instance[uid] = image
        uids.insert(uid)
        enqueueCheckSize()
    }
    
    func contains(uid: String) -> Bool {
        if InMemoryImageCache.instance[uid] != nil {
            return true
        } else {
            return permitted ? uids.contains(uid) : false
        }
    }
    
    private func enqueueCheckSize() {
        if permitted {
            enqueueSelector("checkSizeInBackground")
        }
    }
    
    private var checkingState = false
    
    func checkSizeInBackground() {
        guard !checkingState else {
            return
        }
        checkingState = true
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            let result = self.checkSize()
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                if result && self.permitted {
                    self.fetchUIDs()
                }
                self.checkingState = false
            }
        }
    }
    
    func fetchUIDs() {
        do {
            self.uids = Set(try NSFileManager.defaultManager().contentsOfDirectoryAtPath(self.path))
        } catch {
        }
    }
    
    private func checkSize() -> Bool {
        let limitSize = self.size
        guard limitSize > 0 && permitted else {
            return false
        }
        do {
            let manager = NSFileManager.defaultManager()
            var size = 0
            var urls = try manager.contentsOfDirectoryAtURL(NSURL(fileURLWithPath: self.path, isDirectory: true), includingPropertiesForKeys: [NSURLTotalFileAllocatedSizeKey], options: .SkipsSubdirectoryDescendants)
            for url in urls {
                if let _size = url.resource(NSURLTotalFileAllocatedSizeKey) as? NSNumber {
                    size += _size.integerValue
                }
            }
            if size <= limitSize {
                return false
            }
            let sortKey = NSURLCreationDateKey
            urls.sortInPlace({ (url1, url2) -> Bool in
                guard let date1 = url1.resource(sortKey) as? NSDate,
                    let date2 = url2.resource(sortKey) as? NSDate else {
                        return false
                }
                return date1.compare(date2) == .OrderedAscending
            })
            
            while size > limitSize {
                if let url = urls.first, let index = urls.indexOf(url) {
                    if let _size = url.resource(NSURLTotalFileAllocatedSizeKey) as? NSNumber {
                        try manager.removeItemAtURL(url)
                        size -= _size.integerValue
                        urls.removeAtIndex(index)
                    }
                    
                }
            }
        } catch {
        }
        return true
    }
    
    func clear() {
        do {
            for uid in uids {
                try NSFileManager.defaultManager().removeItemAtPath(getPath(uid))
            }
            uids.removeAll()
        } catch {
        }
    }
    
    func setImage(image: UIImage) -> String {
        let uid = NSString.GUID()
        write(image, uid: uid)
        return uid
    }
    
    func setImageAtPath(path: String, uid: String) {
        guard permitted && path.isExistingFilePath else {
            return
        }
        do {
            let manager = NSFileManager.defaultManager()
            let toPath = getPath(uid)
            try manager.copyItemAtPath(path, toPath: toPath)
            if InMemoryImageCache.instance[path] != nil {
                InMemoryImageCache.instance[path] = nil
            }
            if let data = manager.contentsAtPath(toPath) {
                InMemoryImageCache.instance[uid] = UIImage(data: data)
            }
            uids.insert(uid)
        } catch {
        }
    }
    
    func setImageData(data: NSData, uid: String) {
        guard permitted else {
            return
        }
        data.writeToFile(getPath(uid), atomically:false)
        uids.insert(uid)
        enqueueCheckSize()
    }
    
    func imageWithURL(url: String) -> UIImage? {
        return read(ImageCache.uidFromURL(url))
    }
    
    func setImage(image: UIImage, withURL url: String) {
        write(image, uid: ImageCache.uidFromURL(url))
    }
    
    func setImageAtPath(path: String, withURL url: String) {
        if !url.isEmpty {
            setImageAtPath(path, uid: ImageCache.uidFromURL(url))
        }
    }
    
    func containsImageWithURL(url: String) -> Bool {
        return contains(ImageCache.uidFromURL(url))
    }
    
    class func uidFromURL(url: String) -> String {
        if let hash = hashes[url] {
            return hash
        } else {
            let hash = url.md5()
            hashes[url] = hash
            return hash
        }
    }
    
    private static var hashes = [String:String]()
}

extension NSURL {
    func resource(key: String) -> AnyObject? {
        do {
            return try resourceValuesForKeys([key])[key]
        } catch {
            return nil
        }
    }
}