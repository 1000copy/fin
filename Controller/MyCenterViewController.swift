//
//  MyCenterViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 2/7/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit

class MyCenterViewController: MemberViewController {
    var settingsButton:UIButton?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.settingsButton!.contentMode = .center
        self.settingsButton!.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -20)
        self.settingsButton!.setImage(UIImage.imageUsedTemplateMode("ic_supervisor_account")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.settingsButton!.addTarget(self, action: #selector(accountManagerClick), for: .touchUpInside)
        self.settingsButton!.isHidden = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.settingsButton!)
    }
    
    override func getSuccess(_ aModel: MemberModel) {
        super.getSuccess(aModel)
        self.settingsButton!.isHidden = false
    }
    
    func accountManagerClick(){
        Msg.send("openAccountsManager")
    }
}
