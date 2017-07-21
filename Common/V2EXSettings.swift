//
//  V2EXSettings.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/24/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit

let keyPrefix =  "me.fin.V2EXSettings."

class V2EXSettings: NSObject {
    static let sharedInstance = V2EXSettings()
    fileprivate override init(){
        super.init()
    }
    
    subscript(key:String) -> String? {
        get {
            return UserDefaults.standard.object(forKey: keyPrefix + key) as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: keyPrefix + key )
        }
    }
}
// print(self.className()) ,用来替代手写的keyPrefix等字符串。
extension NSObject{
    func className()->String{
        return "\(Mirror(reflecting: self).subjectType)"
    }
}
    
