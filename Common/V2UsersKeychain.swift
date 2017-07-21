//
//  V2Keychain.swift
//  V2ex-Swift
//
//  Created by huangfeng on 2/11/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit

let USERKEY = "USERKEY"
class UserListKeychain {
    static let shared = UserListKeychain()
    fileprivate(set) var users:[String:LoginUser] = [:]
    
    fileprivate init() {
        let _ = loadUsersDict()
    }
    
    func addUser(_ user:LoginUser){
        if let username = user.username , let _ = user.password {
            self.users[username] = user
            self.saveUsersDict()
        }
        else {
            assert(false, "username & password must not be 'nil'")
        }
    }
    func addUser(_ username:String,password:String,avata:String? = nil) {
        let user = LoginUser()
        user.username = username
        user.password = password
        user.avatar = avata
        self.addUser(user)
    }
    
    
    func saveUsersDict(){
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(self.users)
        archiver.finishEncoding()
        let _ = Keychain.save(USERKEY,data as Data)
    }
    func loadUsersDict() -> [String:LoginUser]{
        if users.count <= 0 {
            let data = Keychain.load(USERKEY)
            if let data = data{
                let archiver = NSKeyedUnarchiver(forReadingWith: data)
                let usersDict = archiver.decodeObject()
                archiver.finishDecoding()
                if let usersDict = usersDict as? [String : LoginUser] {
                    self.users = usersDict
                }
            }
        }
        return self.users
    }
    
    func removeUser(_ username:String){
        self.users.removeValue(forKey: username)
        self.saveUsersDict()
    }
    func removeAll(){
        self.users = [:]
        self.saveUsersDict()
    }
    
    func update(_ username:String,password:String? = nil,avatar:String? = nil){
        if let user = self.users[username] {
            if let password = password {
                user.password = password
            }
            if let avatar = avatar {
                user.avatar = avatar
            }
            self.saveUsersDict()
        }
    }
    
}


/// 将会序列化后保存进keychain中的 账户model
class LoginUser :NSObject, NSCoding {
    var username:String?
    var password:String?
    var avatar:String?
    override init(){
        
    }
    required init?(coder aDecoder: NSCoder){
        self.username = aDecoder.decodeObject(forKey: "username") as? String
        self.password = aDecoder.decodeObject(forKey: "password") as? String
        self.avatar = aDecoder.decodeObject(forKey: "avatar") as? String
    }
    func encode(with aCoder: NSCoder){
        aCoder.encode(self.username, forKey: "username")
        aCoder.encode(self.password, forKey: "password")
        aCoder.encode(self.avatar, forKey: "avatar")
    }
}
