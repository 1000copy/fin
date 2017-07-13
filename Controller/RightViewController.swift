//
//  RightViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/14/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit
import FXBlurView

class RightViewController: UIViewController{
    
    /**
     第一次自动高亮的cell，
     因为再次点击其他cell，这个cell并不会自动调用 setSelected 取消自身的选中状态
     所以保存这个cell用于手动取消选中状态
     我也不知道这是不是BUG，还是我用法不对。
    */
    
    
    var backgroundImageView:UIImageView?
    var frostedView = FXBlurView()
    
    fileprivate var _tableView :RightTable!
    fileprivate var tableView: RightTable {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = RightTable();
            
            return _tableView!;
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor;
        
        var currentTab = V2EXSettings.sharedInstance[kHomeTab]
        if currentTab == nil {
            currentTab = "all"
        }
        self.tableView.currentSelectedTabIndex = (tableView.tableData as! RightTableData).rightNodes.index { $0.nodeTab == currentTab }!
        
        self.backgroundImageView = UIImageView()
        self.backgroundImageView!.frame = self.view.frame
        self.backgroundImageView!.contentMode = .left
        view.addSubview(self.backgroundImageView!)

        frostedView.underlyingView = self.backgroundImageView!
        frostedView.isDynamic = false
        frostedView.frame = self.view.frame
        frostedView.tintColor = UIColor.black
        self.view.addSubview(frostedView)
        
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            if V2EXColor.sharedInstance.style == V2EXColor.V2EXColorStyleDefault {
                self?.backgroundImageView?.image = UIImage(named: "32.jpg")
            }
            else{
                self?.backgroundImageView?.image = UIImage(named: "12.jpg")
            }
            self?.frostedView.updateAsynchronously(true, completion: nil)
        }
        
        let rowHeight = self._tableView.tableView(self.tableView, heightForRowAt: IndexPath(row: 0, section: 0))
        let rowCount = self._tableView.tableView(self.tableView, numberOfRowsInSection: 0)
        let paddingTop = (SCREEN_HEIGHT - CGFloat(rowCount) * rowHeight) / 2
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: paddingTop))
    }
    func maximumRightDrawerWidth() -> CGFloat{
        // 调整RightView宽度
        let cell = RightNodeTableViewCell()
        let cellFont = UIFont(name: cell.nodeNameLabel.font.familyName, size: cell.nodeNameLabel.font.pointSize)
        for node in (tableView.tableData as! RightTableData).rightNodes {
            let size = node.nodeName!.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT)),
                                                   options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                   attributes: ["NSFontAttributeName":cellFont!],
                                                   context: nil)
            let width = size.width + 50
            if width > 100 {
                return width
            }
        }
        return 100
    }
   }

fileprivate class RightTableData : TableDataSource{
    let arr = ["tech","creative","play","apple","jobs","deals","city","qna","hot","all","r2","nodes","members",]
    var rightNodes:[rightNodeModel] = []
    var nodes : [TableDataSourceItem] = []
    override init() {
        for item in arr{
            var  a : TableDataSourceItem = [:]
            a["nodeName"] =  NSLocalizedString(item )
            a["nodeTab"] =  item
//            a.setValue( NSLocalizedString(item ), forKey: "nodeName")
//            a.setValue( item, forKey: "nodeTab")
            nodes.append(a)
            rightNodes.append( rightNodeModel(nodeName: NSLocalizedString(item ), nodeTab: item))
        }
    }
    override func rowCount(_ section: Int) -> Int {
        return rightNodes.count;
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        return 48
    }
    override func cellTypeAt(_ indexPath: IndexPath) -> UITableViewCell.Type {
        return RightNodeTableViewCell.self
    }
    override func getDataItem(_ indexPath: IndexPath) -> TableDataSourceItem {
//        return rightNodes[indexPath.row]
        return nodes[indexPath.row]
    }
}
fileprivate class RightTable : RightTableWithData{
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        tableData = RightTableData()
        backgroundColor = UIColor.clear
        estimatedRowHeight=100;
        separatorStyle = .none;
        registerCell(RightNodeTableViewCell.self)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
fileprivate class RightTableWithData : DataTableBase{
    fileprivate override func didSelectRowAt(_ indexPath: IndexPath) {
        super.didSelectRowAt(indexPath)
        if let highLightCell = self.firstAutoHighLightCell{
            self.firstAutoHighLightCell = nil
            if(indexPath.row != self.currentSelectedTabIndex){
                highLightCell.setSelected(false, animated: false)
            }
        }
        let node = self.tableData.getDataItem(indexPath)
        Msg.send("ChangeTab",[node["nodeTab"] as! String])
        Msg.send("closeDrawer")
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.currentSelectedTabIndex && cell.isSelected == false {
            if let highLightCell = self.firstAutoHighLightCell{
                highLightCell.setSelected(false, animated: false)
            }
            self.firstAutoHighLightCell = cell;
            cell.setSelected(true, animated: true)
        }
    }
    var currentSelectedTabIndex = 0;
    var firstAutoHighLightCell:UITableViewCell?
}

struct rightNodeModel {
    var nodeName:String?
    var nodeTab:String?
}
fileprivate class RightNodeTableViewCell: CellBase {
    fileprivate override func load(_ data : TableDataSource,_ item : TableDataSourceItem,_ indexPath : IndexPath){
        nodeNameLabel.text = item["nodeName"] as! String
    }
    override fileprivate func action(_ indexPath: IndexPath) {
        print(indexPath)
    }
    
    var nodeNameLabel: UILabel = {
        let label = UILabel()
        label.font = v2Font(15)
        return label
    }()
    
    var panel = UIView()
    override func setup()->Void{
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        
        self.contentView.addSubview(panel)
        self.panel.snp.makeConstraints{ (make) -> Void in
            make.left.top.right.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-1 * SEPARATOR_HEIGHT)
        }
        
        panel.addSubview(self.nodeNameLabel)
        self.nodeNameLabel.snp.makeConstraints{ (make) -> Void in
            make.right.equalTo(panel).offset(-22)
            make.centerY.equalTo(panel)
        }
        
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            self?.refreshBackgroundColor()
            self?.nodeNameLabel.textColor = V2EXColor.colors.v2_LeftNodeTintColor
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated);
        self.refreshBackgroundColor()
    }
    func refreshBackgroundColor() {
        if self.isSelected {
            self.panel.backgroundColor = V2EXColor.colors.v2_LeftNodeBackgroundHighLightedColor
        }
        else{
            self.panel.backgroundColor = V2EXColor.colors.v2_LeftNodeBackgroundColor
        }
    }
}
