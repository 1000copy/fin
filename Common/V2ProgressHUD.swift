//
//  V2ProgressHUD.swift
//  V2ex-Swift
//
//  Created by skyline on 16/3/29.
//  Copyright © 2016年 Fin. All rights reserved.
//

import UIKit
//import SVProgressHUD
//
//open class V2ProgressHUD: NSObject {
//    open class func show() {
//        SVProgressHUD.show(with: .none)
//    }
//
//    open class func showWithClearMask() {
//        SVProgressHUD.show(with: .clear)
//    }
//
//    open class func dismiss() {
//        SVProgressHUD.dismiss()
//    }
//
//    open class func showWithStatus(_ status:String!) {
//        SVProgressHUD.show(withStatus: status)
//    }
//
//    open class func success(_ status:String!) {
//        SVProgressHUD.showSuccess(withStatus: status)
//    }
//
//    open class func error(_ status:String!) {
//        SVProgressHUD.showError(withStatus: status)
//    }
//
//    open class func inform(_ status:String!) {
//        SVProgressHUD.showInfo(withStatus: status)
//    }
//    open class func setup(){
//        SVProgressHUD.setForegroundColor(UIColor(white: 1, alpha: 1))
//        SVProgressHUD.setBackgroundColor(UIColor(white: 0.15, alpha: 0.85))
//        SVProgressHUD.setDefaultMaskType(.none)
//    }
//}

import PKHUD

public func V2Success(_ status:String!) {
//    V2ProgressHUD.success(status)
    HUD.hide()
    HUD.flash(.success)
}

public func V2Error(_ status:String!) {
//    V2ProgressHUD.error(status)
    HUD.flash(.error)
}

public func V2Inform(_ status:String!) {
//    V2ProgressHUD.inform(status)
    HUD.flash(.label(status))
}

public func V2BeginLoading() {
//    V2ProgressHUD.show()
    HUD.show(.progress)
}

public func V2BeginLoadingWithStatus(_ status:String!) {
//    V2ProgressHUD.showWithStatus(status)
    HUD.flash(.labeledProgress(title: status, subtitle: ""))
}

public func V2EndLoading() {
//    V2ProgressHUD.dismiss()
    HUD.hide()
}
public func HUDsetup() {
//    V2ProgressHUD.setup()
}
