//
//  TestUserPicker.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

struct TestUser {
    
    static func testUser(info: [String:String]) -> Authorization {
        let authorization = Authorization()
        authorization.deviceUID = info["deviceUID"] ?? ""
        authorization.countryCode = info["countryCode"]
        authorization.phone = info["phone"]
        authorization.email = info["email"]
        authorization.password = info["password"]
        return authorization
    }
    
    private static let separator = ","
    
    static func deserializeTestUser(string: String) -> Authorization? {
        let components = string.componentsSeparatedByString(separator)
        guard components.count == 5 else { return nil }
        let authorization = Authorization()
        authorization.deviceUID = components[0]
        authorization.countryCode = components[1].isEmpty ? nil : components[1]
        authorization.phone = components[2].isEmpty ? nil : components[2]
        authorization.email = components[3]
        authorization.password = components[4]
        return authorization
    }
    
    static func serializeTestUser(user: Authorization) -> String? {
        guard let email = user.email, let password = user.password else { return nil }
        return "\(user.deviceUID)\(separator)\(user.countryCode ?? "")\(separator)\(user.phone ?? "")\(separator)\(email ?? "")\(separator)\(password ?? "")"
    }
    
    static func add(authorization: Authorization = Authorization.current, completion: (String? -> Void)? = nil) {
        
        guard let user = serializeTestUser(authorization) else {
            completion?(nil)
            return
        }
        
        get {
            var users = $0
            if !users.contains(user) {
                users.insert(user, atIndex: 0)
                put(users, completion: { completion?($0?.localizedDescription) })
            } else {
                Dispatch.mainQueue.async({
                    completion?(nil)
                })
            }
        }
    }
    
    static func remove(authorization: Authorization, completion: (Void -> Void)? = nil) {
        guard let user = serializeTestUser(authorization) else {
            completion?()
            return
        }
        
        get {
            var users = $0
            if let index = users.indexOf(user) {
                users.removeAtIndex(index)
                put(users, completion: { (error) -> Void in
                    completion?()
                })
            } else {
                Dispatch.mainQueue.async({ completion?() })
            }
        }
    }
    
    private static func remoteRequest(method: String) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: "http://jsonblob.com/api/jsonBlob/56e699ade4b01190df54cac3")!)
        request.HTTPMethod = method
        return request
    }
    
    private static func put(users: [String], completion: NSError? -> Void) {
        let request = remoteRequest("PUT")
        request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(users, options: [])
        let putTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (_, _, error) -> Void in
            Dispatch.mainQueue.async({ completion(error) })
        }
        putTask.resume()
    }
    
    private static func get(completion: [String] -> Void) {
        let request = remoteRequest("GET")
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, _, _) -> Void in
            Dispatch.mainQueue.async({
                if let data = data, let users = (try? NSJSONSerialization.JSONObjectWithData(data, options: [])) as? [String] {
                    completion(users)
                } else {
                    completion([])
                }
            })
        }
        task.resume()
    }
    
    static func testUsers(completion: [Authorization] -> Void) {
        get {
            var users = [Authorization]()
            $0.all({
                if let user = deserializeTestUser($0) {
                    users.append(user)
                }
            })
            (NSDictionary.plist("test-users")?[Environment.current.name] as? [[String:String]])?.all({
                users.append(testUser($0))
            })
            completion(users)
        }
    }
}

class TestUserCell: StreamReusableView, FlowerMenuConstructor {
    
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var deviceUID: UILabel!
    @IBOutlet weak var active: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        FlowerMenu.sharedMenu.registerView(self)
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        menu.addDeleteAction { [weak self] () -> Void in
            if let authorization = self?.entry as? Authorization {
                TestUser.remove(authorization, completion: {
                    TestUser.testUsers { [weak self] authorizations in
                        (self?.superview?.superview as? TestUserPicker)?.dataSource.items = authorizations
                    }
                })
            }
        }
    }
    
    override func setup(entry: AnyObject?) {
        if let authorization = entry as? Authorization {
            phone.text = authorization.fullPhoneNumber
            email.text = authorization.email
            deviceUID.text = authorization.deviceUID
            active.hidden = authorization.password?.isEmpty ?? true
        }
    }
}

final class TestUserPicker: UIView {
    
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .Custom)
    private let navigationBar = UIView()
    private let streamView = StreamView()
    private var dataSource: StreamDataSource!
    
    class func showInView(view: UIView, selection: Authorization -> Void) {
        TestUserPicker(frame: view.bounds).showInView(view, selection: selection)
    }
    
    private func showInView(view: UIView, selection: Authorization -> Void) {
        titleLabel.text = "Select user"
        titleLabel.textColor = UIColor.whiteColor()
        closeButton.setTitle("Close", forState: .Normal)
        navigationBar.backgroundColor = Color.orange
        backgroundColor = UIColor.whiteColor()
        dataSource = StreamDataSource(streamView: streamView)
        dataSource.autogeneratedMetrics.change {
            $0.identifier = "TestUserCell"
            $0.size = 110
            $0.selection = { [weak self] item, entry in
                self?.removeFromSuperview()
                selection(entry as! Authorization)
            }
        }
        navigationBar.addSubview(closeButton)
        navigationBar.addSubview(titleLabel)
        addSubview(navigationBar)
        addSubview(streamView)
        view.addSubview(self)
        
        navigationBar.snp_makeConstraints { (make) -> Void in
            make.top.left.right.equalTo(self)
            make.height.equalTo(64)
        }
        
        closeButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(navigationBar).offset(10)
            make.left.equalTo(navigationBar).offset(12)
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(navigationBar).offset(10)
            make.centerX.equalTo(navigationBar)
        }
        
        streamView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(navigationBar.snp_bottom)
            make.bottom.left.right.equalTo(self)
        }
        
        layoutIfNeeded()
        closeButton.addTarget(self, action: #selector(UIView.removeFromSuperview), forControlEvents: .TouchUpInside)
        
        TestUser.testUsers { [weak self] authorizations in
            self?.dataSource.items = authorizations
        }
    }
}
