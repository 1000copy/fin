//
//  V2ex+Define.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/11/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit

let EMPTY_STRING = "" ;

let SCREEN_WIDTH = UIScreen.mainScreen().bounds.size.width;
let SCREEN_HEIGHT = UIScreen.mainScreen().bounds.size.height;

extension UIImage {
    convenience init? (imageNamed: String){
        self.init(named: imageNamed, inBundle: nil, compatibleWithTraitCollection: nil)
    }
}