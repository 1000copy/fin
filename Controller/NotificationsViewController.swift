//
//  NotificationsViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 1/29/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit
import MJRefresh
class NotificationsViewController: UIViewController{
    fileprivate weak var _loadView:V2LoadingView?
    func showLoadingView (){
        self._loadView = V2LoadingView(view)
    }
    func hideLoadingView() {
        self._loadView?.hideLoadingView()
    }
    fileprivate var _tableView :TableNotify!
    fileprivate var tableView: TableNotify {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = TableNotify();
            _tableView.vc = self
            return _tableView!;
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView);
        self.title = NSLocalizedString("notifications")
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.right.bottom.left.equalTo(self.view);
        }
        self.tableView.scrollUp = refresh
        self.showLoadingView()
        self.tableView.beginScrollUp()
    }
    func refresh(_ cb : @escaping Callback){
        NotificationsModel.getNotifications {[weak self] (response) -> Void in
            if response.success && response.value != nil {
                if let weakSelf = self{
                    weakSelf.tableView.notificationsArray = response.value!
                    weakSelf.tableView.reloadData()
                }
            }
            self?.tableView.mj_header.endRefreshing()
            self?.hideLoadingView()
            cb()
        }
    }
}
fileprivate class TableNotify : TableBase{
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame:frame,style:style)
        self.backgroundColor = UIColor.clear
        self.estimatedRowHeight=100;
        self.separatorStyle = UITableViewCellSeparatorStyle.none;
        regClass(self, cell: NotificationTableViewCell.self)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var notificationsArray:[NotificationsModel] = []
    var vc : UIViewController!
    override fileprivate func rowCount(_ section: Int) -> Int {
        return self.notificationsArray.count
    }
    override func rowHeight(_ indexPath: IndexPath) -> CGFloat {
        return self.fin_heightForCellWithIdentifier(NotificationTableViewCell.self, indexPath: indexPath) { (cell) -> Void in
            cell.bind(self.notificationsArray[indexPath.row]);
        }
    }
    override  func cellAt (_ indexPath: IndexPath) -> UITableViewCell {
        let cell = getCell(self, cell: NotificationTableViewCell.self, indexPath: indexPath)
        cell.bind(self.notificationsArray[indexPath.row])
        cell.replyButton.tag = indexPath.row
        if cell.replyButtonClickHandler == nil {
            cell.replyButtonClickHandler = { [weak self] (sender) in
                self?.replyClick(sender)
            }
        }
        return cell
    }
    override func didSelectRowAt(_ indexPath: IndexPath) {
        let item = self.notificationsArray[indexPath.row]
        if let id = item.topicId {
            Msg.send("openTopicDetail1", [id])
            deselectRow(at: indexPath, animated: true);
        }
    }
    func replyClick(_ sender:UIButton) {
        let item = self.notificationsArray[sender.tag]
        let tempTopicModel = TopicDetailModel()
        tempTopicModel.topicId = item.topicId
        Msg.send("replyComment", [vc,item.userName!,tempTopicModel])
    }
}
