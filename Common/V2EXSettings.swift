//
//  V2EXSettings.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/24/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit

let keyPrefix =  "me.fin.V2EXSettings."

class Setting: NSObject {
//    let sharedInstance = V2EXSettings()
    static let shared = Setting()
    fileprivate override init(){
        super.init()
    }
    public var kHomeTab : String? {
        get{
            return self[kHomeTab_]
        }
        set{
            self[kHomeTab_] = newValue
        }
    }
    public var kFONTSCALE : String? {
        get{
            return self[kFONTSCALE_]
        }
        set{
            self[kFONTSCALE_] = newValue
        }
    }
    public var STYLE_KEY : String? {
        get{
            return self[STYLE_KEY_]
        }
        set{
            self[STYLE_KEY_] = newValue
        }
    }
    public var kUserName : String? {
        get{
            return self[kUserName_]
        }
        set{
            self[kUserName_] = newValue
        }
    }
    private subscript(key:String) -> String? {
        get {
            return UserDefaults.standard.object(forKey: keyPrefix + key) as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: keyPrefix + key )
        }
    }
    let kHomeTab_ = "me.fin.homeTab"
    let kFONTSCALE_ = "kFontScale"
    let STYLE_KEY_ = "styleKey"
    let kUserName_ = "me.fin.username"
}
// print(self.className()) ,用来替代手写的keyPrefix等字符串。
extension NSObject{
    func className()->String{
        return "\(Mirror(reflecting: self).subjectType)"
    }
}

