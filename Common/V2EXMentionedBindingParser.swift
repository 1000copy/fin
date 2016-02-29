//
//  V2EXMentionedBindingParser.swift
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
        self.regex = try! NSRegularExpression(pattern: "@(\\S+)\\s", options: [.CaseInsensitive])
        super.init()
    }
    
    func parseText(text: NSMutableAttributedString!, selectedRange: NSRangePointer) -> Bool {
        self.regex.enumerateMatchesInString(text.string, options: [.WithoutAnchoringBounds], range: text.yy_rangeOfAll()) { (result, flags, stop) -> Void in
            if let result = result {
                let range = result.range
                if range.location == NSNotFound || range.length < 1 {
                    return ;
                }
                
                if  text.attribute(YYTextBindingAttributeName, atIndex: range.location, effectiveRange: nil) != nil  {
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
