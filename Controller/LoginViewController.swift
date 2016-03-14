//
//  LoginViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/22/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit
import SVProgressHUD
import OnePasswordExtension

public typealias LoginSuccessHandel = (String) -> Void

class LoginViewController: UIViewController {
    
    var successHandel:LoginSuccessHandel?
    
    let backgroundImageView = UIImageView()
    let frostedView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    let userNameTextField = UITextField()
    let passwordTextField = UITextField()
    let loginButton = UIButton()
    let cancelButton = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //初始化界面
        self.setupView()
        
        //初始化1Password
        if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
            let onepasswordButton = UIImageView(image: UIImage(named: "onepassword-button")?.imageWithRenderingMode(.AlwaysTemplate))
            onepasswordButton.userInteractionEnabled = true
            onepasswordButton.frame = CGRectMake(0, 0, 34, 22)
            onepasswordButton.contentMode = .ScaleAspectFit
            onepasswordButton.tintColor = UIColor.whiteColor()
            self.passwordTextField.rightView = onepasswordButton
            self.passwordTextField.rightViewMode = .Always
            onepasswordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "findLoginFrom1Password"))
        }
        
        //绑定事件
        self.loginButton.addTarget(self, action: Selector("loginClick:"), forControlEvents: .TouchUpInside)
        self.cancelButton.addTarget(self, action: Selector("cancelClick"), forControlEvents: .TouchUpInside)
    }
    override func viewDidAppear(animated: Bool) {
        UIView.animateWithDuration(2) { () -> Void in
            self.backgroundImageView.alpha=1;
        }
        UIView.animateWithDuration(20) { () -> Void in
            self.backgroundImageView.frame = CGRectMake(-1*( 1000 - SCREEN_WIDTH )/2, 0, SCREEN_HEIGHT+500, SCREEN_HEIGHT+500);
        }
    }
    
    
    func findLoginFrom1Password(){
        OnePasswordExtension.sharedExtension().findLoginForURLString("v2ex.com", forViewController: self, sender: nil) { (loginDictionary, errpr) -> Void in
            if loginDictionary?.count > 0 {
                self.userNameTextField.text = loginDictionary![AppExtensionUsernameKey] as? String
                self.passwordTextField.text = loginDictionary![AppExtensionPasswordKey] as? String
                
                //密码赋值后，点确认按钮
                self.loginClick(self.loginButton)
            }
        }
    }
    func cancelClick (){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func loginClick(sneder:UIButton){
        var userName:String?
        var password:String?
        if self.userNameTextField.text?.Lenght > 0{
            userName = self.userNameTextField.text! ;
        }
        else{
            self.userNameTextField.becomeFirstResponder()
            return;
        }
        
        if self.passwordTextField.text?.Lenght > 0  {
            password = self.passwordTextField.text!
        }
        else{
            self.passwordTextField.becomeFirstResponder()
            return;
        }
        SVProgressHUD.showWithStatus("正在登陆")
        UserModel.Login(userName!, password: password!){
            (response:V2ValueResponse<String>) -> Void in
            if response.success {
                SVProgressHUD.showSuccessWithStatus("登陆成功")
                let username = response.value!
                NSLog("登陆成功 %@",username)
                //保存下用户名
                V2EXSettings.sharedInstance[kUserName] = username
                
                //将用户名密码保存进keychain （安全保存)
                V2UsersKeychain.sharedInstance.addUser(username, password: password!)
                
                //调用登陆成功回调
                if let handel = self.successHandel {
                    handel(username)
                }
                
                //获取用户信息
                UserModel.getUserInfoByUsername(username,completionHandler: nil)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            else{
                SVProgressHUD.showErrorWithStatus(response.message)
            }
        }
    }    
}


//Mark: - 初始化界面
extension LoginViewController {
    func setupView(){
        self.view.backgroundColor = UIColor.blackColor()
        
        self.backgroundImageView.image = UIImage(named: "32.jpg")
        self.backgroundImageView.frame = self.view.frame
        self.backgroundImageView.contentMode = .ScaleToFill
        self.view.addSubview(self.backgroundImageView)
        backgroundImageView.alpha = 0
        
        self.frostedView.frame = self.view.frame
        self.view.addSubview(self.frostedView)
        
        let vibrancy = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark))
        let vibrancyView = UIVisualEffectView(effect: vibrancy)
        vibrancyView.userInteractionEnabled = true
        vibrancyView.frame = self.frostedView.frame
        self.frostedView.contentView.addSubview(vibrancyView)
        
        let v2exLabel = UILabel()
        v2exLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 32)!;
        v2exLabel.text = "V2EX"
        vibrancyView.contentView.addSubview(v2exLabel);
        v2exLabel.snp_makeConstraints{ (make) -> Void in
            make.centerX.equalTo(vibrancyView)
            make.top.equalTo(vibrancyView).offset(40)
        }
        
        let v2exSummaryLabel = UILabel()
        v2exSummaryLabel.font = v2Font(13);
        v2exSummaryLabel.text = "创意者的工作社区"
        vibrancyView.contentView.addSubview(v2exSummaryLabel);
        v2exSummaryLabel.snp_makeConstraints{ (make) -> Void in
            make.centerX.equalTo(vibrancyView)
            make.top.equalTo(v2exLabel.snp_bottom).offset(2)
        }
        
        self.userNameTextField.textColor = UIColor.whiteColor()
        self.userNameTextField.backgroundColor = UIColor(white: 1, alpha: 0.1);
        self.userNameTextField.font = v2Font(15)
        self.userNameTextField.layer.cornerRadius = 3;
        self.userNameTextField.layer.borderWidth = 0.5
        self.userNameTextField.keyboardType = .ASCIICapable
        self.userNameTextField.layer.borderColor = UIColor(white: 1, alpha: 0.8).CGColor;
        self.userNameTextField.placeholder = "用户名"
        self.userNameTextField.clearButtonMode = .Always
        
        let userNameIconImageView = UIImageView(image: UIImage(named: "ic_account_circle")!.imageWithRenderingMode(.AlwaysTemplate));
        userNameIconImageView.frame = CGRectMake(0, 0, 34, 22)
        userNameIconImageView.tintColor = UIColor.whiteColor()
        userNameIconImageView.contentMode = .ScaleAspectFit
        self.userNameTextField.leftView = userNameIconImageView
        self.userNameTextField.leftViewMode = .Always
        
        vibrancyView.contentView.addSubview(self.userNameTextField);
        
        self.userNameTextField.snp_makeConstraints{ (make) -> Void in
            make.top.equalTo(v2exSummaryLabel.snp_bottom).offset(25)
            make.centerX.equalTo(vibrancyView)
            make.width.equalTo(300)
            make.height.equalTo(38)
        }
        
        self.passwordTextField.textColor = UIColor.whiteColor()
        self.passwordTextField.backgroundColor = UIColor(white: 1, alpha: 0.1);
        self.passwordTextField.font = v2Font(15)
        self.passwordTextField.layer.cornerRadius = 3;
        self.passwordTextField.layer.borderWidth = 0.5
        self.passwordTextField.keyboardType = .ASCIICapable
        self.passwordTextField.secureTextEntry = true
        self.passwordTextField.layer.borderColor = UIColor(white: 1, alpha: 0.8).CGColor;
        self.passwordTextField.placeholder = "密码"
        self.passwordTextField.clearButtonMode = .Always
        
        let passwordIconImageView = UIImageView(image: UIImage(named: "ic_lock")!.imageWithRenderingMode(.AlwaysTemplate));
        passwordIconImageView.frame = CGRectMake(0, 0, 34, 22)
        passwordIconImageView.contentMode = .ScaleAspectFit
        userNameIconImageView.tintColor = UIColor.whiteColor()
        self.passwordTextField.leftView = passwordIconImageView
        self.passwordTextField.leftViewMode = .Always
        
        vibrancyView.contentView.addSubview(self.passwordTextField);
        
        self.passwordTextField.snp_makeConstraints{ (make) -> Void in
            make.top.equalTo(self.userNameTextField.snp_bottom).offset(15)
            make.centerX.equalTo(vibrancyView)
            make.width.equalTo(300)
            make.height.equalTo(38)
        }
        
        self.loginButton.setTitle("登  录", forState: .Normal)
        self.loginButton.titleLabel!.font = v2Font(20)
        self.loginButton.layer.cornerRadius = 3;
        self.loginButton.layer.borderWidth = 0.5
        self.loginButton.layer.borderColor = UIColor(white: 1, alpha: 0.8).CGColor;
        vibrancyView.contentView.addSubview(self.loginButton);
        
        self.loginButton.snp_makeConstraints{ (make) -> Void in
            make.top.equalTo(self.passwordTextField.snp_bottom).offset(20)
            make.centerX.equalTo(vibrancyView)
            make.width.equalTo(300)
            make.height.equalTo(38)
        }
        let forgetPasswordLabel = UILabel()
        forgetPasswordLabel.alpha = 0.5
        forgetPasswordLabel.font = v2Font(12)
        forgetPasswordLabel.text = "忘记密码了?"
        
        vibrancyView.contentView.addSubview(forgetPasswordLabel);
        
        forgetPasswordLabel.snp_makeConstraints{ (make) -> Void in
            make.top.equalTo(self.loginButton.snp_bottom).offset(14)
            make.right.equalTo(self.loginButton)
        }
        
        let footLabel = UILabel()
        footLabel.alpha = 0.5
        footLabel.font = v2Font(12)
        footLabel.text = "© 2016 Fin"
        
        vibrancyView.contentView.addSubview(footLabel);
        
        footLabel.snp_makeConstraints{ (make) -> Void in
            make.bottom.equalTo(vibrancyView).offset(-20)
            make.centerX.equalTo(vibrancyView)
        }
        
        self.cancelButton.contentMode = .Center
        cancelButton .setImage(UIImage(named: "ic_cancel")!.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        vibrancyView.contentView.addSubview(cancelButton)
        cancelButton.snp_makeConstraints{ (make) -> Void in
            make.centerY.equalTo(footLabel)
            make.right.equalTo(vibrancyView).offset(-5)
            make.width.height.equalTo(40)
        }
    }
}