//
//  TopicDetailViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/16/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit

class TopicDetailViewController: BaseViewController{
    
    var topicId = "0"
    var currentPage = 1
//
//    fileprivate var model:TopicDetailModel?
//    fileprivate var commentsArray:[TopicCommentModel] = []
    fileprivate var webViewContentCell:TopicDetailWebViewContentCell?
    
    fileprivate var _tableView :Table1!
    fileprivate var tableView: Table1 {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = Table1();
            _tableView.viewControler = self
//            _tableView.model = model
            _tableView.tableView = _tableView
//            _tableView.commentsArray = commentsArray
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
            
            _tableView.backgroundColor = V2EXColor.colors.v2_backgroundColor
            regClass(_tableView, cell: TopicDetailHeaderCell.self)
            regClass(_tableView, cell: TopicDetailWebViewContentCell.self)
            regClass(_tableView, cell: TopicDetailCommentCell.self)
            regClass(_tableView, cell: BaseDetailTableViewCell.self)

            
            return _tableView!;
            
        }
    }
    /// 忽略帖子成功后 ，调用的闭包
    var ignoreTopicHandler : ((String) -> Void)?
    //点击右上角more按钮后，弹出的 activityView
    //只在activityView 显示在屏幕上持有它，如果activityView释放了，这里也一起释放。
    fileprivate weak var activityView:V2ActivityViewController?
    
    //MARK: - 页面事件
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("postDetails")
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.view.addSubview(self.tableView);
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.contentMode = .center
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -15)
        rightButton.setImage(UIImage(named: "ic_more_horiz_36pt")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        rightButton.addTarget(self, action: #selector(TopicDetailViewController.rightClick), for: .touchUpInside)
        
        
        self.showLoadingView()
        self.getData()
        
        self.tableView.mj_header = V2RefreshHeader(refreshingBlock: {[weak self] in
            self?.getData()
        })
        self.tableView.mj_footer = V2RefreshFooter(refreshingBlock: {[weak self] in
            self?.getNextPage()
        })
    }
    
    func getData(){
        //根据 topicId 获取 帖子信息 、回复。
        TopicDetailModel.getTopicDetailById(self.topicId){
            (response:V2ValueResponse<(TopicDetailModel?,[TopicCommentModel])>) -> Void in
            if response.success {
                
                if let aModel = response.value!.0{
                    self.tableView.model = aModel
                }
                
                self._tableView.commentsArray = response.value!.1
                
                self.currentPage = 1
                
                //清除将帖子内容cell,因为这是个缓存，如果赋值后，就会cache到这个变量，之后直接读这个变量不重新赋值。
                //这里刷新了，则可能需要更新帖子内容cell ,实际上只是重新调用了 cell.load(_:)方法
                self.webViewContentCell = nil
                
                self.tableView.reloadData()
                
            }
            else{
                V2Error("刷新失败");
            }
            if self.tableView.mj_header.isRefreshing(){
                self.tableView.mj_header.endRefreshing()
            }
            self.tableView.mj_footer.resetNoMoreData()
            self.hideLoadingView()
        }
    }
    
    /**
     点击右上角 more 按钮
     */
    func rightClick(){
        if  self._tableView.model != nil {
            let activityView = V2ActivityViewController()
            activityView.dataSource = self
            self.navigationController!.present(activityView, animated: true, completion: nil)
            self.activityView = activityView
        }
    }
    /**
     点击节点
     */
    
    
    /**
     获取下一页评论，如果有的话
     */
    func getNextPage(){
        if self._tableView.model == nil || self._tableView.commentsArray.count <= 0 {
            self.endRefreshingWithNoDataAtAll()
            return;
        }
        self.currentPage += 1
        
        if self._tableView.model == nil || self.currentPage > self._tableView.model!.commentTotalPages {
            self.endRefreshingWithNoMoreData()
            return;
        }
        
        TopicDetailModel.getTopicCommentsById(self.topicId, page: self.currentPage) { (response) -> Void in
            if response.success {
                self._tableView.commentsArray += response.value!
                self.tableView.reloadData()
                self.tableView.mj_footer.endRefreshing()
                
                if self.currentPage == self._tableView.model?.commentTotalPages {
                    self.endRefreshingWithNoMoreData()
                }
            }
            else{
                self.currentPage -= 1
            }
        }
    }
    
    /**
     禁用上拉加载更多，并显示一个字符串提醒
     */
    func endRefreshingWithStateString(_ string:String){
        (self.tableView.mj_footer as! V2RefreshFooter).noMoreDataStateString = string
        self.tableView.mj_footer.endRefreshingWithNoMoreData()
    }

    func endRefreshingWithNoDataAtAll() {
        self.endRefreshingWithStateString("暂无评论")
    }

    func endRefreshingWithNoMoreData() {
        self.endRefreshingWithStateString("没有更多评论了")
    }
}



//MARK: - UITableView DataSource
enum TopicDetailTableViewSection: Int {
    case header = 0, comment, other
}

enum TopicDetailHeaderComponent: Int {
    case title = 0,  webViewContent, other
}
extension Table1: UIActionSheetDelegate {
    
    func selectedRowWithActionSheet(_ indexPath:IndexPath){
        self.deselectRow(at: indexPath, animated: true);
        let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil, otherButtonTitles: "回复", "感谢" ,"查看对话")
        actionSheet.tag = indexPath.row
        actionSheet.show(in: self)
    }
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        if buttonIndex > 0 && buttonIndex <= 3 {
            self.perform([#selector(replyComment(_:)),#selector(thankComment(_:)),#selector(relevantComment(_:))][buttonIndex - 1], with: actionSheet.tag)
        }
    }
    func replyComment(_ row:NSNumber){
        V2User.sharedInstance.ensureLoginWithHandler {
            let item = self.commentsArray[row as Int]
            Msg.send("replyComment", [viewControler as Any,item.userName as Any,self.model!])
        }
    }
    func thankComment(_ row:NSNumber){
        guard V2User.sharedInstance.isLogin else {
            V2Inform("请先登录")
            return;
        }
        let item = self.commentsArray[row as Int]
        if item.replyId == nil {
            V2Error("回复replyId为空")
            return;
        }
        if self.model?.token == nil {
            V2Error("帖子token为空")
            return;
        }
        item.favorites += 1
        self.reloadRows(at: [IndexPath(row: row as Int, section: 1)], with: .none)
        
        TopicCommentModel.replyThankWithReplyId(item.replyId!, token: self.model!.token!) {
            [weak item, weak self](response) in
            if response.success {
            }
            else{
                V2Error("感谢失败了")
                //失败后 取消增加的数量
                item?.favorites -= 1
                self?.reloadRows(at: [IndexPath(row: row as Int, section: 1)], with: .none)
            }
        }
    }
    func relevantComment(_ row:NSNumber){
        let item = self.commentsArray[row as Int]
        let relevantComments = TopicCommentModel.getRelevantCommentsInArray(self.commentsArray, firstComment: item)
        if relevantComments.count <= 0 {
            return;
        }
        Msg.send("relevantComment", [viewControler as Any,relevantComments])
    }
}

class Table1:  TableBase{
    var viewControler : UIViewController?
    var topicId = "0"
    var currentPage = 1
    var tableView : TableBase?
    fileprivate var model:TopicDetailModel?
    fileprivate var commentsArray:[TopicCommentModel] = []
    fileprivate var webViewContentCell:TopicDetailWebViewContentCell?
    override func sectionCount() -> Int {
        return 2
    }
   
    override func rowCount(_ section: Int) -> Int {
        let _section = TopicDetailTableViewSection(rawValue: section)!
        switch _section {
        case .header:
            if self.model != nil{
                return 3
            }
            else{
                return 0
            }
        case .comment:
            return self.commentsArray.count;
        case .other:
            return 0;
        }
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        let _section = TopicDetailTableViewSection(rawValue: indexPath.section)!
        var _headerComponent = TopicDetailHeaderComponent.other
        if let headerComponent = TopicDetailHeaderComponent(rawValue: indexPath.row) {
            _headerComponent = headerComponent
        }
        switch _section {
        case .header:
            switch _headerComponent {
            case .title:
                return tableView!.fin_heightForCellWithIdentifier(TopicDetailHeaderCell.self, indexPath: indexPath) { (cell) -> Void in
                    cell.bind(self.model!);
                }
            case .webViewContent:
                if let height =  self.webViewContentCell?.contentHeight , height > 0 {
                    return self.webViewContentCell!.contentHeight
                }
                else {
                    return 1
                }
            case .other:
                return 45
            }
        case .comment:
            let layout = self.commentsArray[indexPath.row].textLayout!
            return layout.textBoundingRect.size.height + 12 + 35 + 12 + 12 + 1
        case .other:
            return 200
        }
    }
    override func cellAt(_ indexPath: IndexPath) -> UITableViewCell {
        let _section = TopicDetailTableViewSection(rawValue: indexPath.section)!
        var _headerComponent = TopicDetailHeaderComponent.other
        if let headerComponent = TopicDetailHeaderComponent(rawValue: indexPath.row) {
            _headerComponent = headerComponent
        }

        switch _section {
        case .header:
            switch _headerComponent {
            case .title:
                //帖子标题
                let cell = getCell(tableView!, cell: TopicDetailHeaderCell.self, indexPath: indexPath);
                if(cell.nodeClickHandler == nil){
                    cell.nodeClickHandler = {[weak self] () -> Void in
                        self?.nodeClick()
                    }
                }
                cell.bind(self.model!);
                return cell;
            case .webViewContent:
                //帖子内容
                if self.webViewContentCell == nil {
                    self.webViewContentCell = getCell(tableView!, cell: TopicDetailWebViewContentCell.self, indexPath: indexPath);
                    self.webViewContentCell?.parentScrollView = self.tableView
                }
                else {
                    return self.webViewContentCell!
                }
                self.webViewContentCell!.load(self.model!);
                if self.webViewContentCell!.contentHeightChanged == nil {
                    self.webViewContentCell!.contentHeightChanged = { [weak self] (height:CGFloat) -> Void  in
                        if let weakSelf = self {
                            //在cell显示在屏幕时更新，否则会崩溃会崩溃会崩溃
                            //另外刷新清空旧cell,重新创建这个cell ,所以 contentHeightChanged 需要判断cell是否为nil
                            if let cell = weakSelf.webViewContentCell, weakSelf.tableView!.visibleCells.contains(cell) {
                                if let height = weakSelf.webViewContentCell?.contentHeight, height > 1.5 * SCREEN_HEIGHT{ //太长了就别动画了。。
                                    UIView.animate(withDuration: 0, animations: { () -> Void in
                                        self?.tableView!.beginUpdates()
                                        self?.tableView!.endUpdates()
                                    })
                                }
                                else {
                                    self?.tableView!.beginUpdates()
                                    self?.tableView!.endUpdates()
                                }
                            }
                        }
                    }
                }
                return self.webViewContentCell!
            case .other:
                let cell = getCell(tableView!, cell: BaseDetailTableViewCell.self, indexPath: indexPath)
                cell.detailMarkHidden = true
                cell.titleLabel.text = self.model?.topicCommentTotalCount
                cell.titleLabel.font = v2Font(12)
                cell.backgroundColor = V2EXColor.colors.v2_CellWhiteBackgroundColor
//                cell.backgroundColor = .blue
                cell.separator.image = createImageWithColor(self.backgroundColor!)
                return cell
//            case .other:
//                return UITableViewCell()
            }
        case .comment:
            let cell = getCell(tableView!, cell: TopicDetailCommentCell.self, indexPath: indexPath)
            cell.bind(self.commentsArray[indexPath.row])
            return cell
        case .other:
            return UITableViewCell();
        }
    }
    
    override func didSelectRowAt(_  indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.selectedRowWithActionSheet(indexPath)
        }
    }
    
    func nodeClick() {
        Msg.send("openNodeTopicList",[self.model?.node,self.model?.nodeName])
    }
}

//MARK: - V2ActivityView
enum V2ActivityViewTopicDetailAction : Int {
    case block = 0, favorite, grade, explore
}

extension TopicDetailViewController: V2ActivityViewDataSource {
    func V2ActivityView(_ activityView: V2ActivityViewController, numberOfCellsInSection section: Int) -> Int {
        return 4
    }
    func V2ActivityView(_ activityView: V2ActivityViewController, ActivityAtIndexPath indexPath: IndexPath) -> V2Activity {
        return V2Activity(title: [
            NSLocalizedString("ignore"),
            NSLocalizedString("favorite"),
            NSLocalizedString("thank"),
            "Safari"][indexPath.row], image: UIImage(named: ["ic_block_48pt","ic_grade_48pt","ic_favorite_48pt","ic_explore_48pt"][indexPath.row])!)
    }
    func V2ActivityView(_ activityView:V2ActivityViewController ,heightForFooterInSection section: Int) -> CGFloat{
        return 45
    }
    func V2ActivityView(_ activityView:V2ActivityViewController ,viewForFooterInSection section: Int) ->UIView?{
        let view = UIView()
        view.backgroundColor = V2EXColor.colors.v2_ButtonBackgroundColor
        
        let label = UILabel()
        label.font = v2Font(18)
        label.text = NSLocalizedString("reply2")
        label.textAlignment = .center
        label.textColor = UIColor.white
        view.addSubview(label)
        label.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(view)
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TopicDetailViewController.reply)))
        
        return view
    }
    
    func V2ActivityView(_ activityView: V2ActivityViewController, didSelectRowAtIndexPath indexPath: IndexPath) {
        activityView.dismiss()
        let action = V2ActivityViewTopicDetailAction(rawValue: indexPath.row)!
        
        guard V2User.sharedInstance.isLogin
            // 用safari打开是不用登录的
            || action == V2ActivityViewTopicDetailAction.explore else {
            V2Inform("请先登录")
            return;
        }
        switch action {
        case .block:
            V2BeginLoading()
            if let topicId = self._tableView.model?.topicId  {
                TopicDetailModel.ignoreTopicWithTopicId(topicId, completionHandler: {[weak self] (response) -> Void in
                    if response.success {
                        V2Success("忽略成功")
                        self?.navigationController?.popViewController(animated: true)
                        self?.ignoreTopicHandler?(topicId)
                    }
                    else{
                        V2Error("忽略失败")
                    }
                    })
            }
        case .favorite:
            V2BeginLoading()
            if let topicId = self._tableView.model?.topicId ,let token = self._tableView.model?.token {
                TopicDetailModel.favoriteTopicWithTopicId(topicId, token: token, completionHandler: { (response) -> Void in
                    if response.success {
                        V2Success("收藏成功")
                    }
                    else{
                        V2Error("收藏失败")
                    }
                })
            }
        case .grade:
            V2BeginLoading()
            if let topicId = self._tableView.model?.topicId ,let token = self._tableView.model?.token {
                TopicDetailModel.topicThankWithTopicId(topicId, token: token, completionHandler: { (response) -> Void in
                    if response.success {
                        V2Success("成功送了一波铜币")
                    }
                    else{
                        V2Error("没感谢成功，再试一下吧")
                    }
                })
            }
        case .explore:
            UIApplication.shared.openURL(URL(string: V2EXURL + "t/" + self._tableView.model!.topicId!)!)
        }
    }
    
    func reply(){
        self.activityView?.dismiss()
        Msg.send("replyTopic", [self._tableView.model!,self.navigationController])
    }
    
}
