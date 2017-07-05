//
//  HomeViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/8/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit
import SnapKit

import Alamofire
import AlamofireObjectMapper

import Ji
import MJRefresh
let kHomeTab = "me.fin.homeTab"
class HomeViewController: UIViewController {
    var tab:String? = nil
    var currentPage = 0
    fileprivate var tableView: TableHome {
        get{
            return TableHome.shared
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        V2Client.sharedInstance.drawerController?.openDrawerGestureModeMask = .panningCenterView
    }
    override func viewWillDisappear(_ animated: Bool) {
        V2Client.sharedInstance.drawerController?.openDrawerGestureModeMask = []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title="V2EX";
        self.tab = V2EXSettings.sharedInstance[kHomeTab]
        self.setupNavigationItem()
        
        //监听程序即将进入前台运行、进入后台休眠 事件
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        tableView.scrollUp = refresh
        tableView.scrollDown = getNextPage
        refreshPage()
        self.thmemChangedHandler = {[weak self] (style) -> Void in
            self?.tableView.backgroundColor = V2EXColor.colors.v2_backgroundColor
        }
    }
    func refreshPage(){
        V2EXSettings.sharedInstance[kHomeTab] = tab
        self.tableView.beginScrollUp()
    }
    func setupNavigationItem(){
        let leftButton = NotificationMenuButton()
        leftButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
        leftButton.addTarget(self, action: #selector(leftClick), for: .touchUpInside)
        
        
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.contentMode = .center
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -15)
        rightButton.setImage(UIImage.imageUsedTemplateMode("ic_more_horiz_36pt")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        rightButton.addTarget(self, action: #selector(rightClick), for: .touchUpInside)

    }
    func leftClick(){
        Msg.send("openLeftDrawer")
    }
    func rightClick(){
        Msg.send("openRightDrawer")
    }
    func refresh(_ cb : @escaping  Callback){
        //根据 tab name 获取帖子列表
        TopicListModel.getTopicList(tab){
            (response) -> Void in
            if response.success {
                self.tableView.topicList = response.value
                self.tableView.reloadData()
                //判断标签是否能加载下一页, 不能就提示下
                let refreshFooter = self.tableView.mj_footer as! V2RefreshFooter
                if self.tab == nil || self.tab == "all" {
                    refreshFooter.noMoreDataStateString = nil
                    refreshFooter.resetNoMoreData()
                }
                else{
                    refreshFooter.noMoreDataStateString = "没更多帖子了,只有【\(NSLocalizedString("all"))】标签能翻页"
                    refreshFooter.endRefreshingWithNoMoreData()
                }
                //重置page
                self.currentPage = 0
                
            }
            cb()
        }
    }
    
    func getNextPage(_ cb : @escaping CallbackMore){
        if let count = self.tableView.topicList?.count , count <= 0{
            self.tableView.mj_footer.endRefreshing()
            return;
        }
        //根据 tab name 获取帖子列表
        self.currentPage += 1
        TopicListModel.getTopicList(tab,page: self.currentPage){
            (response:V2ValueResponse<[TopicListModel]>) -> Void in
            
            if response.success {
                if let count = response.value?.count, count > 0 {
                    self.tableView.topicList? += response.value!
                    self.tableView.reloadData()
                }
            }
            else{
                //加载失败，重置page
                self.currentPage -= 1
            }
            cb(true)
        }
    }
    
    static var lastLeaveTime = Date()
    func applicationWillEnterForeground(){
        //计算上次离开的时间与当前时间差
        //如果超过2分钟，则自动刷新本页面。
        let interval = -1 * HomeViewController.lastLeaveTime.timeIntervalSinceNow
        if interval > 120 {
            self.tableView.mj_header.beginRefreshing()
        }
    }
    func applicationDidEnterBackground(){
        HomeViewController.lastLeaveTime = Date()
    }
}

fileprivate class  TableHome : TableBase {
    static fileprivate var _tableView :TableHome!
    fileprivate class var shared: TableHome {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = TableHome();
            return _tableView!;
        }
    }
    var topicList:Array<TopicListModel>?
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        separatorStyle = UITableViewCellSeparatorStyle.none;
        regClass(self, cell: HomeTopicListTableViewCell.self);
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    override func sectionCount() -> Int {
        return 1
    }
    override func rowCount(_ section: Int) -> Int {
        if let list = self.topicList {
            return list.count;
        }
        return 0;
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        let item = self.topicList![indexPath.row]
        let titleHeight = item.topicTitleLayout?.textBoundingRect.size.height ?? 0
        let height = fixHeight ()  + titleHeight
        return height
    }
    override  func cellAt(_ indexPath: IndexPath) -> UITableViewCell{
        let cell = getCell(self, cell: HomeTopicListTableViewCell.self, indexPath: indexPath);
        cell.bind(self.topicList![indexPath.row]);
        return cell;
    }
    override func didSelectRowAt(_ indexPath: IndexPath) {
        let item = self.topicList![indexPath.row]
        if let id = item.topicId {
            let a = {[weak self] (topicId : String)->Void in
                self?.perform(#selector(self?.ignoreTopicHandler(_:)), with: topicId, afterDelay: 0.6)
            }
            Msg.send("open topic detail",[id,a])
            deselectRow(at: indexPath, animated: true);
        }
    }
    func fixHeight()-> CGFloat{
        let height = 12    +  35     +  12    +  12      + 8
        return CGFloat(height)
        //          上间隔   头像高度  头像下间隔     标题下间隔 cell间隔
    }
    // 当用户点击忽略按钮（在TopicDetailController内），执行它
    func ignoreTopicHandler(_ topicId:String) {
        let index = self.topicList?.index(where: {$0.topicId == topicId })
        if index == nil {
            return
        }
        //看当前忽略的cell 是否在可视列表里
        let indexPaths = indexPathsForVisibleRows
        let visibleIndex =  indexPaths?.index(where: {($0 as IndexPath).row == index})
        
        self.topicList?.remove(at: index!)
        //如果不在可视列表，则直接reloadData 就可以
        if visibleIndex == nil {
            reloadData()
            return
        }
        //如果在可视列表，则动画删除它
        beginUpdates()
        deleteRows(at: [IndexPath(row: index!, section: 0)], with: .fade)
        endUpdates()
    }
    
}
