//
//  WritingViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/25/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit
import YYText


class V2EXMentionedBindingParser: NSObject ,YYTextParser{
    var regex:NSRegularExpression
    override init() {
        self.regex = try! NSRegularExpression(pattern: "@(\\S+)\\s", options: [.caseInsensitive])
        super.init()
    }
    
    func parseText(_ text: NSMutableAttributedString?, selectedRange: NSRangePointer?) -> Bool {
        guard let text = text else {
            return false;
        }
        self.regex.enumerateMatches(in: text.string, options: [.withoutAnchoringBounds], range: text.yy_rangeOfAll()) { (result, flags, stop) -> Void in
            if let result = result {
                let range = result.range
                if range.location == NSNotFound || range.length < 1 {
                    return ;
                }
                
                if  text.attribute(YYTextBindingAttributeName, at: range.location, effectiveRange: nil) != nil  {
                    return ;
                }
                
                let bindlingRange = NSMakeRange(range.location, range.length-1)
                let binding = YYTextBinding()
                binding.deleteConfirm = true ;
                text.yy_setTextBinding(binding, range: bindlingRange)
                text.yy_setColor(colorWith255RGB(0, g: 132, b: 255), range: bindlingRange)
            }
        }
        return false;
    }
    
}


class WritingViewController: UIViewController ,YYTextViewDelegate {

    var textView:YYTextView?
    var topicModel :TopicDetailModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "写东西"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(WritingViewController.leftClick))

        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.contentMode = .center
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -20)
        rightButton.setImage(UIImage(named: "ic_send")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        rightButton.addTarget(self, action: #selector(WritingViewController.rightClick), for: .touchUpInside)
        
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.textView = YYTextView()
        self.textView!.scrollsToTop = false
        self.textView!.backgroundColor = V2EXColor.colors.v2_TextViewBackgroundColor
        self.textView!.font = v2Font(18)
        self.textView!.delegate = self
        self.textView!.textColor = V2EXColor.colors.v2_TopicListUserNameColor
        self.textView!.textParser = V2EXMentionedBindingParser()
        textView!.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)
        textView?.keyboardDismissMode = .interactive
        self.view.addSubview(self.textView!)
        self.textView!.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view)
        }
        
    }
    
    func leftClick (){
        self.dismiss(animated: true, completion: nil)
    }
    func rightClick (){
        
    }
    
    func textViewDidChange(_ textView: YYTextView) {
        if textView.text.Lenght == 0{
            textView.textColor = V2EXColor.colors.v2_TopicListUserNameColor
        }
    }
}

class ReplyingViewController:WritingViewController {
    var atSomeone:String?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("reply")
        if let atSomeone = self.atSomeone {
            let str = NSMutableAttributedString(string: atSomeone)
            str.yy_font = self.textView!.font
            str.yy_color = self.textView!.textColor
            
            self.textView!.attributedText = str
            
            self.textView!.selectedRange = NSMakeRange(atSomeone.Lenght, 0);
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.textView?.becomeFirstResponder()
    }
    
    override func rightClick (){
        if self.textView?.text == nil || (self.textView?.text.Lenght)! <= 0 {
            return;
        }

        V2ProgressHUD.showWithClearMask()
        TopicCommentModelHTTP.replyWithTopicId(self.topicModel!, content: self.textView!.text ) {
            (response) in
            if response.success {
                V2Success("回复成功!")
                self.dismiss(animated: true, completion: nil)
            }
            else{
                V2Error(response.message)
            }
        }
    }
}
